#!/usr/bin/env python3
import os, sys, time, hmac, hashlib, base64, json
import urllib.parse as up
import requests

ACCESS_KEY = os.environ.get("NCP_ACCESS_KEY")
SECRET_KEY = os.environ.get("NCP_SECRET_KEY")
if not ACCESS_KEY or not SECRET_KEY:
    print("NCP_ACCESS_KEY / NCP_SECRET_KEY must be set in env", file=sys.stderr); sys.exit(2)

def sign(method, path, ts, ak, sk):
    msg = f"{method} {path}\n{ts}\n{ak}".encode("utf-8")
    sig = base64.b64encode(hmac.new(sk.encode("utf-8"), msg, hashlib.sha256).digest()).decode("utf-8")
    return sig

def api_get(path, params):
    # VPC 환경
    host = "https://ncloud.apigw.ntruss.com"
    qs   = up.urlencode({**params, "responseFormatType":"json"})
    uri  = f"{path}?{qs}"
    ts   = str(int(time.time()*1000))
    headers = {
        "x-ncp-apigw-timestamp": ts,
        "x-ncp-iam-access-key":  ACCESS_KEY,
        "x-ncp-apigw-signature-v2": sign("GET", uri, ts, ACCESS_KEY, SECRET_KEY),
    }
    r = requests.get(host + uri, headers=headers, timeout=30)
    if r.status_code != 200:
        print(f"HTTP {r.status_code}\n{r.text}", file=sys.stderr); sys.exit(1)
    return r.json()

def main():
    # name 전달 안하면 최신(가장 최근 생성) 멤버 이미지 반환
    name = sys.argv[1] if len(sys.argv) > 1 else None
    res = api_get("/vserver/v2/getMemberServerImageList", {} if not name else {"serverImageName": name})
    body = res.get("getMemberServerImageListResponse") or {}
    items = body.get("memberServerImageList", [])
    if not items:
        print("No member server images found (check name).", file=sys.stderr); sys.exit(3)
    # 최신 하나 고르기 (createDate 내림차순)
    items.sort(key=lambda x: x.get("createDate",""), reverse=True)
    img = items[0]
    img_no   = img.get("memberServerImageNo")
    img_name = img.get("memberServerImageName")
    print(img_no)  # stdout 으로 번호만 출력
if __name__ == "__main__":
    main()
