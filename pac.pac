// google 网站走代理，别的直连
function FindProxyForURL(url, host) {
    if (shExpMatch(url, "*.google.com/*")) {
        return 'PROXY 127.0.0.1:8087'; DIRECT;
    }

    return 'DIRECT';
}