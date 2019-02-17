from json import loads
from logging import getLogger
from os import getenv

from psycopg2 import connect


DB_PASS = getenv("POSTGRES_PASS", default="")
DB_HOSTNAME = getenv("DB_PRIVATE_HOSTNAME", default="")
DB_CONNECTION = connect(host=DB_HOSTNAME, database="webhooks", user="postgres", password=DB_PASS)
LOGGER = getLogger(name="webhooks")


def consume(event, context):
    body = loads(event["body"])
    LOGGER.info("request body: {}".format(body))
    return