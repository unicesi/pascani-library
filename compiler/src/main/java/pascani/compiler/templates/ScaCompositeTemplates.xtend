package pascani.compiler.templates

import org.ow2.scesame.qoscare.core.scaspec.SCABinding
import org.ow2.scesame.qoscare.core.scaspec.SCAComponent
import org.ow2.scesame.qoscare.core.scaspec.SCAPort
import org.ow2.scesame.qoscare.core.scaspec.SCAProperty

/**
 * TODO: wires are not supported in this version
 */
class ScaCompositeTemplates {

	def static String parseComponent(SCAComponent component) {
		'''
			«IF (component.isComposite)»
				<?xml version="1.0" encoding="ISO-8859-15"?>
				<!--
				 Copyright © 2015 Universidad Icesi
				 
				 This file is part of the Pascani DSL.
				 
				 The Pascani DSL is free software: you can redistribute it and/or modify
				 it under the terms of the GNU Lesser General Public License as published by
				 the Free Software Foundation, either version 3 of the License, or (at your
				 option) any later version.
				 
				 The Pascani DSL is distributed in the hope that it will be useful, but
				 WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
				 FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
				 for more details.
				 
				 You should have received a copy of the GNU Lesser General Public License
				 along with The Pascani DSL If not, see http://www.gnu.org/licenses/
				-->
				<composite name="«component.name»"
					xmlns="http://www.osoa.org/xmlns/sca/1.0"
					xmlns:frascati="http://frascati.ow2.org/xmlns/sca/1.1"
					targetNamespace="http://frascati.ow2.org/«component.name»">
					«FOR child : component.children»
						«parseComponent(child)»
					«ENDFOR»
				</composite>
			«ELSE»
				<component name="«component.name»">
					<implementation.java class="«component.clazz»" />
					«FOR service : component.services»
						«parseService(service)»
					«ENDFOR»
					«FOR reference : component.references»
						«parseReference(reference)»
					«ENDFOR»
					«FOR property : component.properties»
						«parseProperty(property)»
					«ENDFOR»
					«FOR child : component.children»
						«parseComponent(child)»
					«ENDFOR»
				</component>
			«ENDIF»
		'''
	}

	def static parseProperty(SCAProperty property) {
		'''
			<property name="«property.name»">«property.value»</property>
		'''
	}

	def static parseService(SCAPort service) {
		'''
			<service name="«service.name»">
				<interface.java interface="«service.implement.clazz»"/>
				«FOR binding : service.bindings»
					«parseBinding(binding)»
				«ENDFOR»
			</service>
		'''
	}

	def static parseReference(SCAPort reference) {
		'''
			<reference name="«reference.name»">
				<interface.java interface="«reference.implement.clazz»"/>
				«FOR binding : reference.bindings»
					«parseBinding(binding)»
				«ENDFOR»
			</reference>
		'''
	}

	def static parseBinding(SCABinding binding) {
		'''
			<frascati:binding.«binding.type.toString.toLowerCase»
				«FOR attribute : binding.attributes»
					«attribute.name»="«attribute.value»"
				«ENDFOR»
			/>
		'''
	}

}
