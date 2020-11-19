package org.jreactapp.bootstrap;

import org.jreactapp.api.Api;
import java.util.logging.Logger;

import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.ContextHandler;

/**
 * Application entry point
 */
public class RunJreactApp {
    private static final Logger logger = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Server createServer(final int port, final String contextPath){
        Server server = new Server(port);

        ContextHandler context = new ContextHandler();
        context.setContextPath(contextPath);
        context.setHandler(new ContainerHandler());

        server.setHandler(context);

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
