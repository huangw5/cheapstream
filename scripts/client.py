#!/usr/bin/env python

import httplib
import json
import logging
import sys

class AceError(Exception):
    pass

def get_stream(server_addr, content_id):
    """Sends getstream request to the server.

    Args:
        server_addr: Server address in host:port format.
        content_id: ID of the content.
    Returns:
        Server response in JSON format.
    Raises:
       AceError if anything goes wrong.
    """
    try:
        conn = httplib.HTTPConnection(server_addr)
        conn.request("GET", "/ace/getstream?id=%s&format=json" % content_id)        
        resp = conn.getresponse()
        if resp.status != 200:
            raise AceError("HTTP status: %d" % resp.status)
        return json.load(resp)
    except Exception as e:
        logging.error("Failed to connect to %s" % server_addr)
        raise AceError(e)


def main(argv):
    data = get_stream(argv[1], argv[2])
    if data["error"] is not None:
        logging.error("Error in get_stream: %s" % data["error"])
        return
    res = data["response"]
    print "stat_url: %s" % res["stat_url"]
    print "playback_url: %s" % res["playback_url"]
    print "command_url: %s" % res["command_url"]

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print "Usage: %s <host:port> <content_id>" % sys.argv[0]
        sys.exit()

    main(sys.argv)
