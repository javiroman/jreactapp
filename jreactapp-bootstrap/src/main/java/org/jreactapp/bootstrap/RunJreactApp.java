package org.jreactapp.bootstrap;

import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.util.resource.PathResource;
import org.jreactapp.api.Api;
import java.util.logging.Logger;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.DefaultHandler;

/**
 * Application entry point
 */
public class RunJreactApp {
    private static final Logger logger = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Server createServer(final int port, final String contextPath){
        Server server = new Server(port);

        // Create the ResourceHandler. It is the object that will actually handle
        // the request for a given file. It is a Jetty Handler object so it is
        // suitable for chaining with other handlers.
        ResourceHandler resourceHandler = new ResourceHandler();

        // Configure the ResourceHandler. Setting the resource base indicates
        // where the files should be served out of.
        resourceHandler.setDirectoriesListed(true);
        resourceHandler.setWelcomeFiles(new String[]{"index.html"});

        Path userDir = Paths.get(System.getProperty("user.dir"));
        PathResource pathResource = new PathResource(userDir);
        resourceHandler.setBaseResource(pathResource);

        // Add the ResourceHandler to the server.
        HandlerList handlers = new HandlerList();
        handlers.setHandlers(new Handler[]{resourceHandler, new DefaultHandler()});
        server.setHandler(handlers);

        return server;
    }

    public static void main( String[] args ) throws Exception {


        Api app = new Api();
        app.greeting();

        logger.info("Starting App Container");
        Server server = createServer(8888, "/");

        server.start();
        server.join();
    }
}
