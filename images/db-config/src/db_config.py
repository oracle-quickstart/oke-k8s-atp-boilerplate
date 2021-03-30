# Copyright (c) 2021, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

from os import environ

import cx_Oracle

from log_util import get_logger


logger = get_logger(__name__, environ.get('LOG_LEVEL'))


def atp_setup(connection, username, password):

    cursor = connection.cursor()
    cursor.execute(f"""
    SELECT * FROM dba_tables
    WHERE table_name = 'MESSAGES' and owner = '{username.upper()}'
    """)
    rows = cursor.fetchall()

    if len(rows) == 0:
        sql = f"""CREATE USER {username}
        IDENTIFIED BY "{password}"
        QUOTA UNLIMITED ON DATA"""
        cursor.execute(sql)
        connection.commit()
        sql = f"""
        CREATE TABLE {username}.messages (
            id RAW(16) DEFAULT SYS_GUID() NOT NULL PRIMARY KEY,
            rcvd_at_ts TIMESTAMP WITH TIME ZONE,
            msg CLOB CONSTRAINT ensure_json CHECK (msg IS JSON)
        )
        """
        cursor.execute(sql)
        connection.commit()
    sql = f"""GRANT CONNECT, CREATE SESSION, CHANGE NOTIFICATION TO {username}"""
    cursor.execute(sql)
    connection.commit()
    sql = f"""GRANT SELECT, INSERT ON {username}.messages TO {username}"""
    cursor.execute(sql)
    connection.commit()


if __name__ == '__main__':

    admin_username = environ.get('DB_ADMIN_USER')
    admin_password = environ.get('DB_ADMIN_PWD')
    username = environ.get('DB_USER')
    password = environ.get('DB_PWD')
    tns_name = environ.get('TNS_NAME')
    cx_Oracle.init_oracle_client(config_dir="/instantclient_21_1/network/admin")

    try:
        with cx_Oracle.connect(
                admin_username,
                admin_password,
                tns_name,
                encoding="UTF-8") as connection:
            logger.info("DB connection OK")
            atp_setup(connection, username, password)
    except Exception as e:
        logger.error(str(e))
