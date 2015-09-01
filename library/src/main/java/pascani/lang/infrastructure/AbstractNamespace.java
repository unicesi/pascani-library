package pascani.lang.infrastructure;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import pascani.lang.Event;
import pascani.lang.events.ChangeEvent;
import pascani.lang.infrastructure.rabbitmq.EndPoint;
import pascani.lang.infrastructure.rabbitmq.RabbitMQProducer;
import pascani.lang.infrastructure.rabbitmq.RabbitMQRpcServer;

/**
 * TODO: documentation
 * 
 * TODO: produce an event when the set method is called (from here not
 * subclasses)
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public abstract class AbstractNamespace implements Namespace, RpcRequestHandler {

	/**
	 * A RabbitMQ end point (a connection to the server)
	 */
	protected final EndPoint endPoint;

	/**
	 * An RPC server configured to serve external requests, for instance, from
	 * {@link Monitor} objects
	 */
	private final RpcServer server;

	/**
	 * The producer sending (variable) change events
	 */
	private final MessageProducer producer;

	/**
	 * The context in which this namespace is used
	 */
	private final pascani.lang.Runtime.Context context;

	/**
	 * TODO: documentation
	 * 
	 * @param uri
	 * @param routingKey
	 * @throws Exception
	 */
	public AbstractNamespace(final String uri, final String routingKey)
			throws Exception {

		this.context = pascani.lang.Runtime.Context.NAMESPACE;
		this.endPoint = new EndPoint(uri);
		this.producer = new RabbitMQProducer(endPoint, getAcceptedClasses(),
				declareQueue(routingKey), routingKey);

		this.server = new RabbitMQRpcServer(endPoint, routingKey,
				pascani.lang.Runtime.Context.NAMESPACE);

		registerProducerAsListener();
		startRpcServer();
	}

	private void registerProducerAsListener() {
		pascani.lang.Runtime.getRuntimeInstance(this.context)
				.registerEventListener(this.producer);
	}

	private String declareQueue(final String routingKey) throws IOException {
		// Create the corresponding namespace queue for the event producer, and
		// then create a binding between the queue and the configured namespace
		// exchange.
		String queue = routingKey;
		String exchange = pascani.lang.Runtime.getRuntimeInstance(this.context)
				.getEnvironment().get("namespace_exchange");

		this.endPoint.channel().queueDeclare(queue, false, true, true, null);
		this.endPoint.channel().queueBind(queue, exchange, routingKey);

		return exchange;
	}

	private List<Class<? extends Event<?>>> getAcceptedClasses() {
		List<Class<? extends Event<?>>> classes = new ArrayList<Class<? extends Event<?>>>();
		classes.add(ChangeEvent.class);

		return classes;
	}

	private void startRpcServer() {
		this.server.setHandler(this);
		this.server.start();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see pascani.lang.infrastructure.RpcRequestHandler#handle(pascani.lang.
	 * infrastructure.RpcRequest)
	 */
	public Serializable handle(RpcRequest request) {
		Serializable response = null;
		String variable = (String) request.getParameter(0);

		if (request.operation().equals(RpcOperation.NAMESPACE_GET_VARIABLE)) {
			response = getVariable(variable);
		} else if (request.operation().equals(
				RpcOperation.NAMESPACE_SET_VARIABLE)) {

			Serializable value = request.getParameter(1);
			response = setVariable(variable, value);
		}

		return response;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see pascani.lang.infrastructure.Namespace#getVariable(java.lang.String)
	 */
	public abstract Serializable getVariable(String variable);

	/*
	 * (non-Javadoc)
	 * 
	 * @see pascani.lang.infrastructure.Namespace#setVariable(java.lang.String,
	 * java.io.Serializable)
	 */
	public abstract Serializable setVariable(String variable, Serializable value);

}
