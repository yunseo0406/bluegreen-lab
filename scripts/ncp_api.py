# ncp_api.py
# -*- coding: utf-8 -*-

import time
import hmac
import hashlib
import base64
import logging
import urllib.parse
import requests
from typing import Dict, Tuple

logger = logging.getLogger("NCP_API")
if not logger.handlers:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

UTF = "UTF-8"

# 리전 프리픽스/서픽스 (네 코드 의도 유지)
TAGS: Dict[str, Tuple[str, str]] = {
    "ncp": ("",     ""),
    "gov": ("",     "gov-"),
    "fin": ("fin-", "fin-"),
}

# 이 호출에서 필요한 건 vserver 뿐이라 최소화
# /vserver/v2  ->  ncloud.
SUB_CNAMES = {
    "ncloud.": ["/vserver/v2"],
}

class NcpApi:
    """
    NCP API v2 간단 클라이언트
    - Access/Secret Key 기반 서명
    - GET 시 path+query 포함 서명 (createServerImage에 필수)
    """
    def __init__(self, access_key: str, secret_key: str, region_type: str = "ncp") -> None:
        self.ak = access_key
        self.sk = secret_key.encode(UTF)
        self.region_type = region_type

        if region_type not in TAGS:
            raise ValueError("unsupported region_type (use one of: ncp, gov, fin)")

    def _base_url_for(self, uri_path: str) -> str:
        """주어진 URI에 맞는 base URL 생성"""
        tag1, tag2 = TAGS[self.region_type]

        sub_cname = None
        for cname, prefixes in SUB_CNAMES.items():
            if any(uri_path.startswith(p) for p in prefixes):
                sub_cname = cname
                break

        if not sub_cname:
            raise ValueError(f"unsupported API path for this client: {uri_path}")

        # 기본은 apigw.
        main_cname = "apigw."

        # (네 코드의 금융/공공 특별 케이스는 여기선 생략 — vserver만 쓰므로 기본값으로 충분)
        return f"https://{tag1}{sub_cname}{main_cname}{tag2}ntruss.com"

    @staticmethod
    def _ts_ms() -> str:
        return str(int(time.time() * 1000))

    def _sign(self, method: str, path_with_query: str, ts: str) -> str:
        """
        v2 서명 포맷:
            {METHOD} {PATH_WITH_QUERY}
            {TIMESTAMP_MS}
            {ACCESS_KEY}
        """
        msg = f"{method} {path_with_query}\n{ts}\n{self.ak}"
        sig = hmac.new(self.sk, msg.encode(UTF), hashlib.sha256).digest()
        return base64.b64encode(sig).decode(UTF)

    def request(self, method: str, uri_path: str, params: Dict[str, str] = None) -> requests.Response:
        """
        단순 요청 (GET만 사용)
        - responseFormatType=json 자동 추가
        - GET 서명에 path+query 포함
        """
        params = dict(params or {})
        params.setdefault("responseFormatType", "json")

        # 쿼리 직렬화(순서 유지하려면 list of tuples로 넘겨도 됨)
        qs = urllib.parse.urlencode(params, doseq=True)
        path_with_query = f"{uri_path}?{qs}" if method.upper() == "GET" else uri_path
        url = self._base_url_for(uri_path) + path_with_query

        ts = self._ts_ms()
        sig = self._sign(method.upper(), path_with_query, ts)

        headers = {
            "x-ncp-apigw-timestamp": ts,
            "x-ncp-iam-access-key": self.ak,
            "x-ncp-apigw-signature-v2": sig,
        }

        logger.info("REQ %s %s", method.upper(), url)
        resp = requests.request(method.upper(), url, headers=headers, timeout=60)
        logger.info("RESP %s", resp.status_code)
        return resp

    # 편의 메서드: createServerImage (파라미터 2개만!)
    def create_server_image(self, server_instance_no: str, server_image_name: str) -> requests.Response:
        uri = "/vserver/v2/createServerImage"
        params = {
            "serverInstanceNo": server_instance_no,
            "serverImageName":  server_image_name,
        }
        return self.request("GET", uri, params=params)
