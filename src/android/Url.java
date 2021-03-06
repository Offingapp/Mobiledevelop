package com.uniface.url;

import android.net.Uri;
import org.apache.cordova.*;
import java.io.FileNotFoundException;
import java.io.IOException;
import org.apache.cordova.CordovaResourceApi;

/**
 This plugin allows Uniface to load local files from the app's resources.
*/
public class Url extends CordovaPlugin {

    private static final String UnifaceScheme = "uniface-app";
    private static final String UnifaceServer = "-uniface-app-";

    // Should we allow the request
    @Override
    public Boolean shouldAllowRequest(String url) {
        LOG.d("Url", "shouldAllowRequest: " + url);
        Uri uri = Uri.parse(url);
        if(UnifaceScheme.equals(uri.getScheme()) || UnifaceServer.equals(uri.getAuthority()) ){
            return true;
        }

        return null;
    }

    // Allow the page to make cordova calls
    @Override
    public Boolean shouldAllowBridgeAccess(String url){
        LOG.d("Url", "shouldAllowBridgeAccess: " + url);
        Uri uri = Uri.parse(url);
        if(UnifaceScheme.equals(uri.getScheme()) || UnifaceServer.equals(uri.getAuthority()) ){
            return true;
        }

        return null;
    }

    // Allow the calls past the Whitelist
    @Override
    public Boolean shouldAllowNavigation(String url) {
        LOG.d("Url", "shouldInterceptRequest: " + url);
        Uri uri = Uri.parse(url);
        if(UnifaceScheme.equals(uri.getScheme()) || UnifaceServer.equals(uri.getAuthority()) ){
            return true;
        }

        return null;
    }

    /**
     * The input should be uniface-app://{/}something of {something}://-uniface-app-/something
     * This will upfate this to  file:///android_asset/www/something
     * once converted it will be packaged up so CordovaResourceApi.OpenForReadResult to open as an standard request
     */
    @Override
    public Uri remapUri(Uri uri) {
        LOG.d("Url", "remapUri: " + uri);

        if(UnifaceScheme.equals(uri.getScheme()) || UnifaceServer.equals(uri.getAuthority()) ){
            // We need to deal with both incorrect and correct schema definitions
            // as Uniface has if incorrectly defined (uniface-app:// rather than uniface-app:///)
            if ( !uri.toString().startsWith(UnifaceScheme + ":///") && UnifaceScheme.equals(uri.getScheme())) {
                uri = Uri.parse(uri.toString().replace(UnifaceScheme + "://", UnifaceScheme + ":///"));
            }

            return toPluginUri(Uri.parse("file:///android_asset/www" + uri.getPath()));
        }
        return null;
    }

    /*
     * Opens a stream to the given URI, also providing the MIME type & length.
     * @return Never returns null.
     * @throws InvalidArgumentException for relative URIs. Relative URIs should be
     *     resolved before being passed into this function.
     * @throws Throws an IOException if the URI cannot be opened.
     * @throws Throws an IllegalStateException if called on a foreground thread and skipThreadCheck is false.
     */
    @Override
    public CordovaResourceApi.OpenForReadResult handleOpenForRead(Uri uri) throws IOException {
        LOG.d("Url", "handleOpenForRead: " + uri);

        try {
            CordovaResourceApi resourceApi = webView.getResourceApi();
            Uri mappedUri = fromPluginUri(uri);
            return resourceApi.openForRead(mappedUri, true);
        }
        catch (FileNotFoundException e) {
            throw new FileNotFoundException("URI not supported by CordovaResourceApi: " + uri);
        }
        catch (IOException e) {
            throw new IOException("URI not supported by CordovaResourceApi: " + uri);
        }
        catch (IllegalStateException e) {
            throw new IllegalStateException("URI not supported by CordovaResourceApi: " + uri);
        }
    }
}
