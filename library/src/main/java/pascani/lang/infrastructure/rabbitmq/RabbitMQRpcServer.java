/*
 * Copyright © 2015 Universidad Icesi
 * 
 * This file is part of the Pascani library.
 * 
 * The Pascani library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 * 
 * The Pascani library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with The SLR Support Tools. If not, see <http://www.gnu.org/licenses/>.
 */
package pascani.lang.infrastructure.rabbitmq;

import java.io.IOException;
import java.io.Serializable;
import java.util.concurrent.TimeoutException;

import org.apache.commons.lang3.SerializationUtils;

import pascani.lang.infrastructure.ProbeOperation;
import pascani.lang.infrastructure.RpcRequest;
import pascani.lang.infrastructure.RpcServer;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;

/**
 * An implementation of {@link RpcServer} for the RabbitMQ queuing system
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public class RabbitMQRpcServer extends RpcServer {

	/**
	 * Extends the default functionality of the RabbitMQ RPC server, providing a
	 * way to handle requests. This implementation removes the ACK confirmation.
	 * 
	 * @author Miguel Jiménez - Initial contribution and API
	 */
	protected class InternalRpcServer extends RpcServer2 {
		public InternalRpcServer(Channel channel, String queueName)
				throws IOException {
			super(channel, queueName);
		}

		@Override public byte[] handleCall(byte[] requestBody,
				AMQP.BasicProperties replyProperties) {

			RpcRequest request = SerializationUtils.deserialize(requestBody);
			Serializable response = delegateHandling(request);
			return SerializationUtils.serialize(response);
		}
	}

	/**
	 * An end point connected to a RabbitMQ queue
	 */
	private final EndPoint endPoint;

	/**
	 * The actual RPC RabbitMQ server
	 */
	private final InternalRpcServer server;

	/**
	 * Creates an instance of a RabbitMQ RPC server, setting the RPC request
	 * queue.
	 * 
	 * @param endPoint
	 * @param RpcRequestQueueName
	 *            The queue designated for RPC requests
	 * 
	 * @throws IOException
	 *             If an I/O problem is encountered in the initialization of the
	 *             actual RabbitMQ RPC server
	 * @throws TimeoutException
	 *             If there is a connection time out when connecting to the
	 *             RabbitMQ server
	 */
	public RabbitMQRpcServer(final EndPoint endPoint,
			String RpcRequestQueueName) throws IOException, TimeoutException {
		super(RpcRequestQueueName);

		this.endPoint = endPoint;

		// More information on the queue name:
		// https://www.rabbitmq.com/direct-reply-to.html
		this.server = new InternalRpcServer(this.endPoint.channel(),
				"amq.rabbitmq.reply-to");
	}

	/*
	 * (non-Javadoc)
	 * @see pascani.runtime.infrastructure.RpcServer#startProcessingRequests(pascani.lang.Probe)
	 */
	@Override public void startProcessingRequests() throws IOException {
		this.server.mainloop();
	}

	@Override public Serializable delegateHandling(RpcRequest request) {
		Serializable response = null;
		long timestamp = (Long) request.getParameter(0);

		if (request.operation().equals(ProbeOperation.CLEAN))
			response = this.probe.cleanData(timestamp);
		else if (request.operation().equals(ProbeOperation.COUNT))
			response = this.probe.count(timestamp);
		else if (request.operation().equals(ProbeOperation.COUNT_AND_CLEAN))
			response = this.probe.countAndClean(timestamp);
		else if (request.operation().equals(ProbeOperation.FETCH))
			response = (Serializable) this.probe.fetch(timestamp);
		else if (request.operation().equals(ProbeOperation.FETCH_AND_CLEAN))
			response = (Serializable) this.probe.fetchAndClean(timestamp);

		return response;
	}

}