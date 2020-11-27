package org.jreactapp.bootstrap;

import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.jreactapp.api.Api;

import java.net.MalformedURLException;
import java.util.logging.Logger;

import org.eclipse.jetty.server.Server;
import org.jreactapp.api.JerseyService;

/**
 * Application entry point
 */
public class RunJreactApp {
    private static final Logger logger = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Server createServer(final int port, final String contextPath)
            throws MalformedURLException {
        System.setProperty("org.eclipse.jetty.LEVEL","DEBUG");

        Server server = new Server(port);

        ServletContextHandler contextHandler = new ServletContextHandler();
        contextHandler.setContextPath("/");

        ServletHolder jerseyServlet = contextHandler.addServlet(
                org.glassfish.jersey.servlet.ServletContainer.class, "/api/*");
        //contextHandler.setInitParameter(ServerProperties.PROVIDER_CLASSNAMES, "org.jree");

        jerseyServlet.setInitParameter( "jersey.config.server.provider.classnames",
                JerseyService.class.getCanonicalName());

        jerseyServlet.setInitOrder(0);


        ServletHolder staticHolder = new ServletHolder(new DefaultServlet());
        staticHolder.setInitParameter("resourceBase", "./lib/ui");
        staticHolder.setInitParameter("dirAllowed", "true");
        contextHandler.addServlet(staticHolder, "/");

        HandlerList handlers = new HandlerList();
        handlers.addHandler(contextHandler);
        handlers.addHandler(new DefaultHandler()); // used to show config errors

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
