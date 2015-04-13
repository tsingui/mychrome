function FindProxyForURL(url, host) {
    if (shExpMatch(url, "*.google.com/*")) {
        return 'PROXY 127.0.0.1:8087'; DIRECT;
    }

    return 'DIRECT';
}