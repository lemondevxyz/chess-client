class ServerConf {
  static const apiver = "v1";
  bool ssl;
  // amount of time to wait, before we completely stop trying to reconnect.
  Duration timeout;

  Uri url;

  String earl(String proto, String path) {
    return Uri.parse(url.toString())
        .replace(scheme: proto, path: path)
        .toString();
  }

  String http(String path) {
    String proto = "http";
    if (this.ssl) {
      proto = "https";
    }

    return this.earl(proto, "/api/${ServerConf.apiver}/$path");
  }

  String ws(String path) {
    String proto = "ws";
    if (this.ssl) {
      proto = "wss";
    }

    return this.earl(proto, "/api/${ServerConf.apiver}/$path");
    //return this.earl(proto, path);
  }

  ServerConf(bool ssl, String host, Duration timeout, {int port}) {
    this.url = Uri(
      host: host,
    );

    if (port != null) this.url = this.url.replace(port: port);

    this.ssl = ssl;
    this.timeout = timeout;
  }
}
