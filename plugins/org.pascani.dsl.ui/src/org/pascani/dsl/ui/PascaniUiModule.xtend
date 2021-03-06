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
package org.pascani.dsl.ui

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.ui.editor.folding.IFoldingRegionProvider
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfiguration
import org.pascani.dsl.ui.custom.highlighting.PascaniHighlightingConfiguration
import org.pascani.dsl.ui.custom.highlighting.PascaniSemanticHighlightingCalculator
import org.pascani.dsl.ui.editor.PascaniFoldingRegionProvider
import org.pascani.dsl.ui.AbstractPascaniUiModule

/**
 * Use this class to register components to be used within the Eclipse IDE.
 * 
 * @author Miguel Jiménez - Initial API and contribution
 */
@FinalFieldsConstructor
class PascaniUiModule extends AbstractPascaniUiModule {

	override Class<? extends ISemanticHighlightingCalculator> bindIdeSemanticHighlightingCalculator() {
		return PascaniSemanticHighlightingCalculator;
	}

	override Class<? extends IHighlightingConfiguration> bindIHighlightingConfiguration() {
		return PascaniHighlightingConfiguration;
	}

	def Class<? extends IFoldingRegionProvider> bindIFoldingRegionProvider() {
		return PascaniFoldingRegionProvider;
	}

}
