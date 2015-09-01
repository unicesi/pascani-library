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

import pascani.lang.Probe;

/**
 * An enumeration containing the types of operations provided by {@link Probe}
 * and {@link BasicNamespace} instances.
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
public enum RpcOperation {
	// Probe operations
	PROBE_CLEAN, PROBE_COUNT, PROBE_COUNT_AND_CLEAN, PROBE_FETCH, PROBE_FETCH_AND_CLEAN,

	// Namespace operations
	NAMESPACE_GET_VARIABLE, NAMESPACE_SET_VARIABLE
}
