import asyncio
import pyatv
import threading
import concurrent.futures
import json
from pyatv.const import Protocol

_loop = None
_thread = None
_atv = None
_pairing = None

def _start_loop(loop):
    asyncio.set_event_loop(loop)
    loop.run_forever()

def init():
    global _loop, _thread
    if _loop is None:
        _loop = asyncio.new_event_loop()
        _thread = threading.Thread(target=_start_loop, args=(_loop,), daemon=True)
        _thread.start()

def scan_devices(ips_csv=None):
    init()
    future = asyncio.run_coroutine_threadsafe(_scan_devices(ips_csv), _loop)
    return future.result()

async def _scan_devices(ips_csv):
    hosts = [ip.strip() for ip in ips_csv.split(',')] if ips_csv else None
    atvs = await pyatv.scan(loop=_loop, hosts=hosts)
    results = []
    for atv in atvs:
        results.append({
            'name': atv.name,
            'identifier': atv.identifier,
            'address': str(atv.address)
        })
    return json.dumps(results)

def connect(identifier, address=None, credentials=None):
    init()
    future = asyncio.run_coroutine_threadsafe(_connect(identifier, address, credentials), _loop)
    return future.result()

async def _connect(identifier, address, credentials):
    global _atv
    hosts = [address] if address else None
    atvs = await pyatv.scan(identifier=identifier, loop=_loop, hosts=hosts)
    if not atvs:
        return False
    
    conf = atvs[0]
    if credentials:
        for proto, cred in json.loads(credentials).items():
            conf.set_credentials(Protocol(int(proto)), cred)
            
    try:
        _atv = await pyatv.connect(conf, loop=_loop, protocol=Protocol.Companion)
        return True
    except Exception as e:
        print(f"Connect error: {e}")
        return False

def start_pairing(identifier, address=None):
    init()
    future = asyncio.run_coroutine_threadsafe(_start_pairing(identifier, address), _loop)
    return future.result()

async def _start_pairing(identifier, address):
    global _pairing
    hosts = [address] if address else None
    atvs = await pyatv.scan(identifier=identifier, loop=_loop, hosts=hosts)
    if not atvs:
        return False
        
    conf = atvs[0]
    _pairing = await pyatv.pair(conf, Protocol.Companion, loop=_loop)
    await _pairing.begin()
    return True

def finish_pairing(pin):
    init()
    future = asyncio.run_coroutine_threadsafe(_finish_pairing(pin), _loop)
    return future.result()

async def _finish_pairing(pin):
    global _pairing
    if not _pairing:
        return ""
        
    _pairing.pin(int(pin))
    await _pairing.finish()
    
    if _pairing.has_paired:
        # Return credentials mapping Protocol.value -> string
        creds = {Protocol.Companion.value: _pairing.service.credentials}
        await _pairing.close()
        _pairing = None
        return json.dumps(creds)
        
    await _pairing.close()
    _pairing = None
    return ""

def send_command(cmd):
    init()
    # Fire and forget to eliminate any queuing delays
    asyncio.run_coroutine_threadsafe(_send_command(cmd), _loop)
    return True

async def _send_command(cmd):
    global _atv
    if not _atv:
        return False
    
    try:
        rc = _atv.remote_control
        if cmd == "up":
            await rc.up()
        elif cmd == "down":
            await rc.down()
        elif cmd == "left":
            await rc.left()
        elif cmd == "right":
            await rc.right()
        elif cmd == "select":
            await rc.select()
        elif cmd == "menu":
            await rc.menu()
        elif cmd == "home":
            await rc.home()
        elif cmd == "play_pause":
            await rc.play_pause()
        elif cmd == "next":
            await rc.next()
        elif cmd == "previous":
            await rc.previous()
        elif cmd == "volume_up":
            await _atv.audio.volume_up()
        elif cmd == "volume_down":
            await _atv.audio.volume_down()
        else:
            return False
        return True
    except Exception as e:
        print(f"Command error: {e}")
        return False

def send_text(text):
    init()
    asyncio.run_coroutine_threadsafe(_send_text(text), _loop)
    return True

async def _send_text(text):
    global _atv
    if not _atv:
        return False
    try:
        if _atv.keyboard.text_focus_state:
            await _atv.keyboard.text_set(text)
            return True
    except Exception as e:
        print(f"Keyboard error: {e}")
    return False

def get_apps():
    init()
    future = asyncio.run_coroutine_threadsafe(_get_apps(), _loop)
    return future.result()

async def _get_apps():
    global _atv
    if not _atv:
        return "[]"
    try:
        apps = await _atv.apps.app_list()
        res = [{"name": app.name, "identifier": app.identifier} for app in apps]
        return json.dumps(res)
    except Exception as e:
        print(f"Apps error: {e}")
        return "[]"

def launch_app(identifier):
    init()
    asyncio.run_coroutine_threadsafe(_launch_app(identifier), _loop)
    return True

async def _launch_app(identifier):
    global _atv
    if not _atv:
        return False
    try:
        await _atv.apps.launch_app(identifier)
        return True
    except Exception as e:
        print(f"Launch error: {e}")
        return False
