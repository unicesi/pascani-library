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
package pascani.lang.util;

import pascani.lang.Event;

/**
 * A simple implementation to encapsulate event generation in probes, monitors
 * and classes within the measurement library.
 * 
 * @param <T>
 *            The type of events to be produced
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public class EventProducer<T extends Event<?>> {

	/**
	 * The default runtime
	 */
	private final pascani.lang.Runtime runtime;

	/**
	 * @param context
	 *            The context in which the runtime resides
	 */
	public EventProducer(pascani.lang.Runtime.Context context) {
		this.runtime = pascani.lang.Runtime.getRuntimeInstance(context);
	}

	/**
	 * Posts an event
	 * 
	 * @param event
	 *            The event to be posted
	 */
	public void post(T event) {
		this.runtime.postEvent(event);
	}

}