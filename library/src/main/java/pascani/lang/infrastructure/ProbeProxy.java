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
package pascani.lang.infrastructure;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.SerializationUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import pascani.lang.Event;
import pascani.lang.Probe;

/**
 * An implementation of {@link Probe} that makes communication transparent for
 * {@link Monitor} instances with remote {@link Probe} objects.
 *
 * @param <T>
 *            The type of events the actual probe handles
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public class ProbeProxy<T extends Event<?>> implements Probe<T> {

	/**
	 * The logger
	 */
	protected final Logger logger = LogManager.getLogger(getClass());

	/**
	 * An RPC client configured to make requests to a specific {@link Probe}
	 */
	private final RpcClient client;

	/**
	 * @param client
	 *            An already configured RPC client, i.e., an initialized client
	 *            that knows a routing key
	 */
	public ProbeProxy(RpcClient client) {
		this.client = client;
	}

	/**
	 * Performs an RPC call to a remote probe
	 * 
	 * @param message
	 *            The payload of the message
	 * @param defaultValue
	 *            A decent value to nicely return in case an {@link Exception}
	 *            is thrown
	 * @return The response from the RPC server (i.e., a remote component
	 *         processing RPC requests) configured with the routing key of the
	 *         {@link RpcClient} instance
	 */
	private byte[] makeActualCall(RpcRequest request, Serializable defaultValue) {
		byte[] message = SerializationUtils.serialize(request);
		byte[] response = SerializationUtils.serialize(defaultValue);
		try {
			response = client.makeRequest(message);
		} catch (Exception e) {
			this.logger.error("Error performing an RPC call to monitor probe "
					+ this.client.routingKey(), e.getCause());
			throw new RuntimeException(e);
		}
		return response;
	}

	public boolean cleanData(long timestamp) {
		RpcRequest request = new RpcRequest(RpcOperation.PROBE_CLEAN, timestamp);
		byte[] response = makeActualCall(request, false);
		return SerializationUtils.deserialize(response);
	}

	public int count(long timestamp) {
		RpcRequest request = new RpcRequest(RpcOperation.PROBE_COUNT, timestamp);
		byte[] response = makeActualCall(request, 0);
		return SerializationUtils.deserialize(response);
	}

	public int countAndClean(long timestamp) {
		RpcRequest request = new RpcRequest(RpcOperation.PROBE_COUNT_AND_CLEAN,
				timestamp);
		byte[] response = makeActualCall(request, 0);
		return SerializationUtils.deserialize(response);
	}

	public List<T> fetch(long timestamp) {
		RpcRequest request = new RpcRequest(RpcOperation.PROBE_FETCH, timestamp);
		byte[] response = makeActualCall(request, new ArrayList<T>());
		return SerializationUtils.deserialize(response);
	}

	public List<T> fetchAndClean(long timestamp) {
		RpcRequest request = new RpcRequest(RpcOperation.PROBE_FETCH_AND_CLEAN,
				timestamp);
		byte[] response = makeActualCall(request, new ArrayList<T>());
		return SerializationUtils.deserialize(response);
	}

}
