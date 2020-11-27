package org.jreactapp.bootstrap;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.handler.HandlerCollection;
import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.glassfish.jersey.server.ServerProperties;
import org.jreactapp.api.Api;

import java.net.MalformedURLException;
import java.util.logging.Logger;

import org.eclipse.jetty.server.Server;

/**
 * Application entry point
 */
public class RunJreactApp {
    private static final Logger logger = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Server createServer(final int port, final String contextPath)
            throws MalformedURLException {

        System.setProperty("org.eclipse.jetty.LEVEL","DEBUG");
        Server server = new Server(port);
        String pwdPath = System.getProperty("user.dir");

        ServletContextHandler staticContext = new ServletContextHandler();
        staticContext.setContextPath("/");

        ServletHolder staticHolder = new ServletHolder(new DefaultServlet());
        staticHolder.setInitParameter("resourceBase", "./lib/ui");
        staticHolder.setInitParameter("pathInfoOnly", "true");
        staticContext.addServlet(staticHolder, "/*");

        ServletContextHandler restContext = new ServletContextHandler();
        ServletHolder restHolder = new ServletHolder();
        restHolder.setInitParameter(ServerProperties.PROVIDER_PACKAGES, "org.jreactapp.api");
        restContext.addServlet(org.glassfish.jersey.servlet.ServletContainer.class,
                        "/api/*");
        //restHolder.setInitOrder(0);

        HandlerCollection handlerCollection = new HandlerCollection();
        handlerCollection.setHandlers(new Handler[] {restContext, staticContext});

        server.setHandler(handlerCollection);

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
