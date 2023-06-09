# default backend definition.  Set this to point to your content server.
backend default {
  .host = "127.0.0.1";
  .port = "80";
}

# add your server IP to allow purges from the backend
acl purge {
  "localhost";
  "127.0.0.1";
}

import std;

sub vcl_recv {
    if(req.backend.healthy) {
		set req.grace = 0s;
    } else {
		set req.grace = 24h;
    }
    if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
		return (pipe);
    }
    # purge request
    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        return(lookup);
    }

    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }
    #Always cache all images & fonts
    #if (req.url ~ "\.(png|gif|jpg|jpeg|swf|js|css|ico)$") {
    if (req.url ~ "\.(jpg|jpeg|png|gif|ico|tiff|tif|bmp|ppm|pgm|xcf|psd|webp|svg|woff|eot|otf|ttf)$") {
      return(lookup);
    }

	return(pipe);
}

sub vcl_fetch {
    #Allow 24hour stale content, before an error 500/404 is thrown
	set beresp.grace = 0s;
    #add ban-lurker tags to object
    set beresp.http.X-Purge-URL = req.url;
    set beresp.http.X-Purge-Host = req.http.host;
	#Respect force-reload, and clear cache accordingly. This means that a ctrl-reload will actually purge
	# the cache for this URL.
	if (req.http.Cache-Control ~ "no-cache") {
        set beresp.ttl = 0s;
        #Make sure ESI includes are processed!
        set beresp.do_esi = true;
        set beresp.http.X-Cacheable = "NO:force-reload";
        #Make sure that We remove alle cache headers, so the Browser does not cache it for us!
        remove beresp.http.Cache-Control;
        remove beresp.http.Expires;
        remove beresp.http.Last-Modified;
        remove beresp.http.ETag;
        remove beresp.http.Pragma;
        return (deliver);
    }
    if (req.url ~ "\.(png|gif|jpg|swf|js|css|html)$") {
        unset beresp.http.set-cookie;
        set beresp.http.X-Cacheable = "YES:jpg,gif,jpg,swf, js and css are always cached";
        #Cache in varnish for one week
        set beresp.ttl   = 1w;
        #Set client age to one hourm see vcl_deliver for explanation of the magicmarker
        set beresp.http.cache-control = "max-age = 3600";
        set beresp.http.magicmarker = "1";
        return (deliver);
    }
    #Allow edgeside includes
    set beresp.do_esi  = true;
    if (beresp.http.Set-Cookie) {
        set beresp.http.X-Cacheable = "NO: Backencd sets cookie";
        #call reset_cache_headers;
        return (hit_for_pass);
    }
    #Since we rely on TYPO3 to send the correct Cache-control headers, we do nothing except for removing the cache-control headers before output
    #Make sure that We remove alle cache headers, so the Browser does not cache it for us!
    remove beresp.http.Cache-Control;
    remove beresp.http.Expires;
    remove beresp.http.Last-Modified;
    remove beresp.http.ETag;
    remove beresp.http.Pragma;
    set beresp.http.X-Cacheable = "NO";
    if(beresp.ttl > 0s) {
        set beresp.http.X-Cacheable = "YES";
    }
    if (req.http.Cookie ~ ".*TYPO3_FE_USER_LOGGED_IN=1.*") {
        set beresp.http.X-Cacheable = "NO, FRONTEND USER LOGGED IN";
    }
    return (deliver);
}

sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set req.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.
    return (pipe);
}

sub vcl_hit {
    #general hit vcl
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }

    if (req.http.Cache-Control ~ "no-cache") {
        set obj.ttl = 0s;
        return (pass);
    }
}

sub vcl_deliver {
    # See: http://varnish-cache.org/trac/wiki/VCLExampleLongerCaching
    if (resp.http.magicmarker) {
        /* Remove the magic marker */
        unset resp.http.magicmarker;
        /* By definition we have a fresh object */
        set resp.http.age = "0";
    }
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 404 "Not in cache";
    }
}

sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    synthetic {"
    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
     <html>
      <head>
      <title>"} + obj.status + " " + obj.response + {"</title>
      <meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
     </head>
    <body>
     <script type="text/javascript">
       function show_moreinfo(var1){
         document.getElementById(var1).style.display="block";
         document.getElementById(var1+"_button").style.display="none";
       }
      </script>
      <div style="color:#A5C642;">
       Der er desv&aelig;rre et problem med at tilg&aring; den &oslash;nskede side.
       <br/>
       Pr&oslash;v venligst igen senere.
      </div>
      <br />
      <div style="color:#949494;">
       The requested page is not available.
       <br/>
       Please try again later.
      </div>
      <br />
      <span id="moreinfo" style="display:none;border:2px #a5c642 solid; width: 550px;">
       <span style="color:#949494;">
        <h2>More information: </h2>
        <h3>Error "} + obj.status + " " + obj.response + {"</h3>
       <p>"} + obj.response + {"</p>
       <p>XID: "} + req.xid + {"</p>
       </span>
      </span>
      <br />
      <input id="moreinfo_button" type="button" value="More information" onclick="show_moreinfo('moreinfo')"/>
      <br /><br />
      <div id="logo">
       <img src="data:image/gif;base64,R0lGODlhaQApAPcAABgYGCkpKTExMTk5OUJCQkpKSlJSUlpaWmNjY2tra3Nzc3t7e4SEhIyMjJSUlJycnKWlpaXGQqXGSqXOSq2tra3OSq3OUq3OWrW1tbXOWrXOY7XWY7XWa729vb3Wa73Wc73We73ee8bGxsbWe8bee8behMbejM7Ozs7ejM7elM7nlM7nnNbW1tbnnNbnpdbnrd7e3t7nrd7ntd7vtd7vvefn5+fvvefvxufvzuf3zu/vzu/v7+/3zu/31u/33vf33vf35/f39/f/7///7///9////////////////////////////////////////////////////////////////////////////////////////////////////////////// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////ywAAAAAaQApAAAI/gCLFCESpMcNGS9cpDBhYgQIEBw+aOCgoaKGCxgvWKzIIeKHhyVMpFjhQgaNHkCCCFzJsqXLlzBjymSJQ0MECTcj5Nyps6dPnD6D5gRKVKeFFERmKl3KtCURDjyLDt2JEyjVqT91Ws3po6nXry+JSI0adKvVsVV7ntUaQUZSsHC9+rjKlu1atGqz1t2aIq5fpjf25hU8eK3duldxgvjLWKYMnokLS8Z6F7FODo0zu3RxGLLhz3o958WZQbNpgSnMdgaN2DBWuhZUns5s4rVqsqClstb6djbjEqHTEm6td7dV2b7/giA7HG9nuqyBJGf8QbDxyHRFC5Y+3S+Hscy1/hMP7 7pr97hQs7sWTn4ye5w9zse1SVi48/WTLeOQD9fmbuj1qbdaTvvx99UF47WXn4CDaXWDgQfepyB2AH72IIRNIQhgg0W5xtxtQBWI4VIXsHbdhPgR2NuIMmnooXMfPgejiCy2iJduMg4XY1001giTi5bhyGF+JuqEw4o+uuRfVi8yWGGAPSbZEn1ONmmbeFJFKeVKUEl45Y5Dthbfli+l52VzQ8JolXlktlTdbVgm6KVUbLa50nKU9XQBCBqEZMIHElgwAkOAaiXBBwyZAIKGN3HgZwmMSsCdnSsBRxxOJQQBxA004BDEDUDgQMMNO+CAEwdA+EDDqp6mcBMN/p+a5CmeEgjBGAYizFabhxGMEASVGhRhAlAXELGcDDjUZUIQEXBAxJIRuBDYTbLV4MACCzDQQRAQINdtBwxg68AOIhhwgAMNdFAEBeEugEERO2Bw7QIdsBBuAzUEscMD2DLwbmrW6VSCEETF1uVNQowgwQ0v5OVBEBaAEERRFmhowUoHQMDCxgTsoAAERQQhwgEwDLAxCw8wAEMCC4ggAgwPIHByAhDAAAAGMJxQgAEnsIDBAEEo0MDJBdTAmXgl7GDVxekhrDDDPH0AscRnWeCBThespEACDnStbg0D7FBEASzUEEDXDjxQQxENPKB1AQnEbUACMBSwUtcrCRAE/gMIoP3uYzmOQHBOFRRxcK0jtGUqWykIEYEGT1mVwlwSBCtQBy530AEBJxSB7shF1IA55g8YUAQD3RaxwMc11LADDLDbLRDeAoXtsgiaG9DBDbtlqpYEkWslBHAa+BAqDsgHsSusyOPQQxCuRrCYQAc8oPnmLIQ8AAHZs0DA9Q4csK7uDyRAQQEYaJ5AA3Xf7cBKYXN9fQEiUD6kBd+xVWhOHFigFQcgKMFD/JeTPgVwUVrpy0B2AIGuPeAEsnmA+EImggd0jQJiC0IHHAABsVUwbdsSmWxgJxANwquBacsVs8JTHNwc5kaDeYFMPEYAGLD oKZdi4VYgs6C1jAkmPEHIl49uAKQW5qkyKaKKCSgFEyKUigYJWYgAQSARilwEIxbIYhYvoEWMZIAjH/hISEbyAmT5AElMLEJAAAA7"/>
     </div>
    </body>
   </html>
     "};
    return (deliver);
}
#custom error page
