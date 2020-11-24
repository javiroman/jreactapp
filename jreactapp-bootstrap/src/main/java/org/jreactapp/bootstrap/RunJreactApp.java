package org.jreactapp.bootstrap;

import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
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
        System.setProperty("org.eclipse.jetty.LEVEL","INFO");

        Server server = new Server(port);

        String pwdPath = System.getProperty("user.dir");

        ServletContextHandler context = new ServletContextHandler();
        context.setContextPath("/");

        ServletHolder staticHolder = new ServletHolder(new DefaultServlet());
        staticHolder.setInitParameter("resourceBase", "./lib/ui");
        staticHolder.setInitParameter("pathInfoOnly", "true");
        context.addServlet(staticHolder, "/*");

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
