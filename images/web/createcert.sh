## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

openssl req -nodes -x509 -newkey rsa:4096 -keyout ./src/server.key -out ./src/server.cert -days 365