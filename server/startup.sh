#!/bin/bash
gunicorn Endian-GPO:app --daemon --pid /var/run/endian-gpo.pid -b 0.0.0.0:7777