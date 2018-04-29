#!/usr/bin/env python

import json
import logging
import subprocess
import sys
import time
import urllib2

stream_path = "/home/huangwe/USB_Storage/ace.strm"

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
    resp = urllib2.urlopen("http://%s/ace/getstream?id=%s&format=json" %
                           (server_addr, content_id))
    if resp.code != 200:
      raise AceError("HTTP status: %d" % resp.code)
    return json.load(resp)
  except Exception as e:
    logging.error("Failed to connect to %s", server_addr)
    raise AceError(e)


def poll_stat(stat_url, play_cmd=None):
  """Keeps polling the stat from the server.

  Raises:
    AceError if anything goes wrong
  """
  try:
    play_started = False
    while True:
      time.sleep(2)
      resp = urllib2.urlopen(stat_url + "&format=json")
      if resp.code != 200:
        raise AceError("HTTP status: %d" % resp.code)
      data = json.load(resp)
      if data["error"] is not None:
        raise AceError(data["error"])

      res = data["response"]
      sys.stdout.write("\rstatus: %6s speed_down: %4d downloaded: %7d peers: %2d" %
                       (res["status"], res["speed_down"], res["downloaded"],
                        res["peers"]))
      sys.stdout.flush()
      if not play_started and play_cmd is not None and res["status"] == "dl":
          subprocess.Popen(play_cmd)
          play_started = True
  except KeyboardInterrupt:
    return
  except Exception as e:
    raise AceError(e)


def stop_stream(command_url):
  """Stops the stream

  Raises:
    AceError if anything goes wrong
  """
  try:
    resp = urllib2.urlopen(command_url + "?method=stop")
    if resp.code != 200:
      raise AceError("HTTP status: %d" % resp.code)
    data = json.load(resp)
    if data["error"] is not None:
      raise AceError(data["error"])
    print "\nStop successfully: %s" % data["response"]
  except Exception as e:
    raise AceError(e)


def main(argv):
  data = get_stream(argv[1], argv[2])
  if data["error"] is not None:
    logging.error("Error in get_stream: %s", data["error"])
    return
  res = data["response"]
  print "playback_url: %s" % res["playback_url"]

  # Write the url to a file.
  with open(stream_path, "w") as f:
      f.write(res["playback_url"])

  play_cmd = [argv[3], res["playback_url"]] if len(argv) == 4 else None
  try:
      poll_stat(res["stat_url"], play_cmd)
  finally:
      stop_stream(res["command_url"])


if __name__ == "__main__":
  if len(sys.argv) < 3 or len(sys.argv) > 4:
    print "Usage: %s <host:port> <content_id> [cmd]" % sys.argv[0]
    sys.exit()

  main(sys.argv)
