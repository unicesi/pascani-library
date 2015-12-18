/*
 * Copyright © 2015 Universidad Icesi
 * 
 * This file is part of the Pascani DSL.
 * 
 * The Pascani DSL is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 * 
 * The Pascani DSL is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with The Pascani DSL. If not, see <http://www.gnu.org/licenses/>.
 */
package org.pascani.ui.editor

import org.eclipse.xtext.ui.editor.folding.DefaultFoldingRegionProvider
import org.eclipse.emf.ecore.EObject
import org.pascani.pascani.Monitor
import org.pascani.pascani.Namespace
import org.pascani.pascani.Event
import org.pascani.pascani.Handler

class PascaniFoldingRegionProvider extends DefaultFoldingRegionProvider {

	override boolean isHandled(EObject eObject) {
		switch (eObject) {
			Monitor,
			Namespace,
			Event,
			Handler: return true
			default: return false
		}
	}

}