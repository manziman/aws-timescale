from logging import getLevelName, getLogger, INFO
from os import getenv

from psycopg2 import connect


DB_PASS = getenv("POSTGRES_PASS", default="")
DB_HOSTNAME = getenv("DB_PRIVATE_HOSTNAME", default="")
DB_CONNECTION = connect(host=DB_HOSTNAME, database="webhook", user="postgres", password=DB_PASS)

LOGGER = getLogger(name="webhooks")
LOGGER.setLevel(getLevelName("INFO"))

def consume(event, context):
    body = event["body"]
    LOGGER.info("request body: {}".format(body))
    return body