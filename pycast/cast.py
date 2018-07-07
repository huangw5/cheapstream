import pychromecast
import readchar
import sys
import threading
import time


def find_cast(device_name):
    chromecasts = pychromecast.get_chromecasts()
    try:
        return next(
            cc for cc in chromecasts if cc.device.friendly_name == device_name)
    except StopIteration:
        print('Cannot find device %s' % device_name)
        print('Available devices: [%s]' % ', '.join(
            cc.device.friendly_name for cc in chromecasts))
        raise
    except:
        raise


def start_cast(cast, url, media_type='video/mp4'):
    cast.wait()
    mc = cast.media_controller
    mc.play_media(url, media_type)
    mc.block_until_active()
    print("Playing on %s: %s" % (cast.device.friendly_name, url))
    t = threading.Thread(target=print_status, args=(mc.status,))
    t.start()
    loop_input(cast)
    t.join()


def loop_input(cast):
    mc = cast.media_controller
    actions = {
        readchar.key.UP: lambda: cast.volume_up(),
        readchar.key.DOWN: lambda: cast.volume_down(),
        readchar.key.RIGHT: lambda: [mc.update_status(), mc.seek(mc.status.current_time + 30)],
        readchar.key.LEFT: lambda: [mc.update_status(), mc.seek(mc.status.current_time - 30)],
        "p": lambda: mc.pause() if mc.status.player_is_playing else mc.play(),
    }
    while True:
        key = readchar.readkey()
        if key == readchar.key.CTRL_C or key == "q":
            mc.stop()
            break
        actions.get(key, lambda: None)()


def print_status(status):
    time.sleep(1)
    while True:
        time.sleep(1)
        sys.stdout.write(
            '\rcontent_type: %-10s stream_type: %-10s player_state: %-10s'
            % (status.content_type, status.stream_type, status.player_state))
        sys.stdout.flush()
        if status.player_is_idle:
            break


def stop_cast(cast):
    mc = cast.media_controller
    mc.stop()
    print("Stop")


if __name__ == "__main__":
    if len(sys.argv) != 3 and len(sys.argv) != 4:
        print('Usage: %s <URL> <Device Name>> [Media Type]' % sys.argv[0])
        sys.exit()

    url = sys.argv[1]
    device_name = sys.argv[2]
    cast = find_cast(device_name)
    try:
        start_cast(cast, url)
    except KeyboardInterrupt:
        stop_cast(cast)
