# NGINX Unit CLI


## Apply an Unit-Specification JSON-File

```json
{
    "listeners": {
        "127.0.0.1:8090": {
            "pass": "upstreams/ldapauth"
        },
        "*:9090": {
            "pass": "routes/usersrv"
        }
    },
    "upstreams": {
        "ldapauth": {
            "servers": {
                "127.0.0.1:8091": {},
                "127.0.0.1:8092": {
                    "weight": 2
                }
            }
        }
    },
    "routes": {
        "usersrv": [
            {
                "match": {
                    "uri": [
                        "*.php",
                        "*.php/*"
                    ]
                },
                "action": {
                    "pass": "applications/usersrv/direct"
                }
            },
            {
                "action": {
                    "share": "/path/to/webroot/webroot",
                    "fallback": {
                        "pass": "applications/usersrv/index"
                    }
                }
            }
        ]
    },
    "applications": {
        "usersrv": {
            "type": "php",
            "targets": {
                "direct": {
                    "root": "/path/to/webroot/webroot"
                },
                "index": {
                    "root": "/path/to/webroot/webroot",
                    "script": "index.php"
                }
            }
        }
    }
}
```