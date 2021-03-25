class ServerConf {
  // amount of time to wait, before we completely stop trying to reconnect.
  bool ssl;
  Duration timeout;

  Uri url;

  String earl(String proto, String path) {
    return Uri(
            scheme: proto, host: this.url.host, port: this.url.port, path: path)
        .toString();
  }

  String http(String path) {
    String proto = "http";
    if (this.ssl) {
      proto = "https";
    }

    return this.earl(proto, path);
  }

  String ws(String path) {
    String proto = "ws";
    if (this.ssl) {
      proto = "wss";
    }

    return this.earl(proto, path);
  }

  ServerConf(bool ssl, String host, int port, Duration timeout) {
    this.url = Uri(
      host: host,
      port: port,
    );
    this.ssl = ssl;
    this.timeout = timeout;
  }
}
