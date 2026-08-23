"""Besucherzaehler.

Liest den aktuellen Zaehlerstand aus Azure Table Storage, erhoeht ihn um
eins und gibt den neuen Wert zurueck. Die Anmeldung erfolgt ueber die
verwaltete Identitaet der Function App, es wird kein Schluessel benoetigt.
"""

import json
import logging
import os

import azure.functions as func
from azure.core import MatchConditions
from azure.core.exceptions import ResourceNotFoundError, ResourceModifiedError
from azure.data.tables import TableClient, UpdateMode
from azure.identity import DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

TABLE_ENDPOINT = os.environ["TABLE_ENDPOINT"]
TABLE_NAME = os.environ["TABLE_NAME"]

PARTITION_KEY = "counter"
ROW_KEY = "visits"
MAX_RETRIES = 5


def _table_client() -> TableClient:
    # DefaultAzureCredential nutzt in Azure die verwaltete Identitaet und
    # lokal die Anmeldung der Azure CLI. Derselbe Code laeuft in beiden
    # Umgebungen ohne Fallunterscheidung.
    return TableClient(
        endpoint=TABLE_ENDPOINT,
        table_name=TABLE_NAME,
        credential=DefaultAzureCredential(),
    )


def _increment(client: TableClient) -> int:
    """Erhoeht den Zaehler mit optimistischer Nebenlaeufigkeitskontrolle.

    Bei gleichzeitigen Aufrufen wuerde ein einfaches Lesen-Schreiben
    Zaehlungen verlieren. Das ETag stellt sicher, dass nur geschrieben
    wird, wenn sich der Eintrag zwischenzeitlich nicht geaendert hat.
    """
    for _ in range(MAX_RETRIES):
        try:
            entity = client.get_entity(PARTITION_KEY, ROW_KEY)
        except ResourceNotFoundError:
            entity = {"PartitionKey": PARTITION_KEY, "RowKey": ROW_KEY, "Count": 1}
            client.create_entity(entity)
            return 1

        entity["Count"] = int(entity.get("Count", 0)) + 1
        try:
            client.update_entity(
                entity,
                mode=UpdateMode.REPLACE,
                etag=entity.metadata["etag"],
                match_condition=MatchConditions.IfNotModified,
            )
            return entity["Count"]
        except ResourceModifiedError:
            continue  # anderer Aufruf war schneller, erneut versuchen

    raise RuntimeError("Zaehler konnte nach mehreren Versuchen nicht erhoeht werden")


@app.route(route="counter", methods=["GET"])
def counter(req: func.HttpRequest) -> func.HttpResponse:
    try:
        with _table_client() as client:
            value = _increment(client)
    except Exception:
        logging.exception("Zaehler nicht verfuegbar")
        return func.HttpResponse(
            json.dumps({"error": "counter unavailable"}),
            status_code=503,
            mimetype="application/json",
        )

    return func.HttpResponse(
        json.dumps({"count": value}),
        mimetype="application/json",
        headers={"Cache-Control": "no-store"},
    )


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    """Einfacher Lebenszeichen-Endpunkt fuer die Zustandspruefung."""
    return func.HttpResponse("ok", mimetype="text/plain")
