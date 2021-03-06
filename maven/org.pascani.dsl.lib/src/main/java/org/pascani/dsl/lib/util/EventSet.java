/*
 * Copyright © 2015 Universidad Icesi
 * 
 * This file is part of the Pascani project.
 * 
 * The Pascani project is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 * 
 * The Pascani project is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with The Pascani project. If not, see <http://www.gnu.org/licenses/>.
 */
package org.pascani.dsl.lib.util;

import java.util.Collection;
import java.util.ConcurrentModificationException;

import org.pascani.dsl.lib.Event;

import com.google.common.base.Predicate;
import com.google.common.collect.Collections2;
import com.google.common.collect.ImmutableSet;

/**
 * A sorted set of {@link Event} objects with logging capabilities (by means of
 * {@link LoggingSortedSet}) and filter methods based on the raising time of
 * each {@link Event}.
 * 
 * @param <T>
 *            The type of events
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public final class EventSet<T extends Event<?>> extends LoggingSortedSet<T> {

	/**
	 * Creates an instance setting the logging format to a {@link String},
	 * delegating the trace format to {@link Event#toString()}
	 */
	public EventSet() {
		super("%s");
	}

	/**
	 * Filters this {@link EventSet} according to a time window, by checking if
	 * the events were raised within the range [{@code start}, {@code end}]; by
	 * means of {@link Event#isInTimeWindow(long, long)}.
	 * 
	 * <b>Note</b>: Before filtering, an immutable copy of this set is made, to
	 * avoid {@link ConcurrentModificationException}.
	 * 
	 * @param start
	 *            The initial timestamp of the filtering criteria, in
	 *            nanoseconds
	 * @param end
	 *            The final timestamp of the filtering criteria, in nanoseconds
	 * @return an {@link EventSet} filtered according to the given time window
	 */
	public EventSet<T> filter(final long start, final long end) {
		Collection<T> filtered = Collections2.filter(freeze(),
				new Predicate<T>() {
					public boolean apply(T event) {
						return event.isInTimeWindow(start, end);
					}
				});
		EventSet<T> filteredSet = new EventSet<T>();
		filteredSet.addAll(filtered);
		return filteredSet;
	}
	
	/**
	 * Counts how many events are in this set according to a time window, by
	 * checking if the events were raised within the range [{@code start},
	 * {@code end}]; by means of {@link Event#isInTimeWindow(long, long)}.
	 * 
	 * <b>Note</b>: Before filtering, an immutable copy of this set is made, to
	 * avoid {@link ConcurrentModificationException}.
	 * 
	 * @param start
	 *            The initial timestamp of the filtering criteria, in
	 *            nanoseconds
	 * @param end
	 *            The final timestamp of the filtering criteria, in nanoseconds
	 * @return The number of events within the given time window
	 */
	public int count(final long start, final long end) {
		int count = 0;
		ImmutableSet<T> frozen = freeze();
		for (T event : frozen) {
			if (event.isInTimeWindow(start, end))
				++count;
		}
		return count;
	}

	/**
	 * Removes the {@link Event} objects raised from {@code start} until
	 * {@code end}.
	 * 
	 * @param start
	 *            The initial timestamp of the filtering criteria
	 * @return the removed {@link Event} objects
	 */
	public synchronized EventSet<T> clean(final long start, final long end) {
		Collection<T> toRemove = filter(start, end);
		synchronized(this) {
			this.standardRemoveAll(toRemove);
		}
		return (EventSet<T>) toRemove;
	}
	
	private ImmutableSet<T> freeze() {
		synchronized(this) {
			return ImmutableSet.copyOf(this);
		}
	}

}
