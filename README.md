# Ayouken Proxy

## Why this project?

I want to use my [bot-API Ayouken](https://github.com/rhannequin/ayouken-api)
on [Gitter](http://gitter.im) chat. But, this chat works with
HTTPS. As long as I don't have my bot on a HTTP server, I need to
use a local HTTPS server that redirects requests to Ayouken.

```bash
$ git clone https://github.com/rhannequin/ayouken-proxy.git
$ cd ayouken-proxy
$ bundle install
$ openssl req -new -x509 -nodes -out server.crt -keyout server.key
$ bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt
```
