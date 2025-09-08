# create_server_image.py
# -*- coding: utf-8 -*-

import os
import sys
import json
import logging
from ncp_api import NcpApi

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <serverInstanceNo> <serverImageName>", file=sys.stderr)
        sys.exit(1)

    server_instance_no = sys.argv[1]
    server_image_name  = sys.argv[2]

    ak = os.getenv("NCP_ACCESS_KEY")
    sk = os.getenv("NCP_SECRET_KEY")
    if not ak or not sk:
        print("NCP_ACCESS_KEY / NCP_SECRET_KEY must be set in env.", file=sys.stderr)
        sys.exit(2)

    # 필요 시 region_type='gov' or 'fin' 으로 바꿔 사용 가능
    api = NcpApi(access_key=ak, secret_key=sk, region_type="ncp")

    resp = api.create_server_image(server_instance_no, server_image_name)

    print("HTTP", resp.status_code)
    try:
        print(json.dumps(resp.json(), ensure_ascii=False, indent=2))
    except Exception:
        print(resp.text)

    # 2xx가 아니면 실패 코드로 종료
    if not (200 <= resp.status_code < 300):
        sys.exit(3)

if __name__ == "__main__":
    main()
