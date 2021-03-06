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
package org.pascani.dsl.validation

import com.google.inject.Inject
import java.io.Serializable
import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.typesystem.references.LightweightTypeReference
import org.pascani.dsl.lib.util.CronConstant
import org.pascani.dsl.pascani.AndEventSpecifier
import org.pascani.dsl.pascani.CronElement
import org.pascani.dsl.pascani.CronElementList
import org.pascani.dsl.pascani.CronExpression
import org.pascani.dsl.pascani.Event
import org.pascani.dsl.pascani.EventEmitter
import org.pascani.dsl.pascani.EventSpecifier
import org.pascani.dsl.pascani.EventType
import org.pascani.dsl.pascani.Handler
import org.pascani.dsl.pascani.ImportEventDeclaration
import org.pascani.dsl.pascani.ImportNamespaceDeclaration
import org.pascani.dsl.pascani.IncrementCronElement
import org.pascani.dsl.pascani.Model
import org.pascani.dsl.pascani.Monitor
import org.pascani.dsl.pascani.Namespace
import org.pascani.dsl.pascani.NthCronElement
import org.pascani.dsl.pascani.OrEventSpecifier
import org.pascani.dsl.pascani.PascaniPackage
import org.pascani.dsl.pascani.RangeCronElement
import org.pascani.dsl.pascani.TerminalCronElement
import org.pascani.dsl.pascani.TypeDeclaration
import org.pascani.dsl.pascani.VariableDeclaration
import java.util.Map

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 * 
 * @author Miguel Jiménez - Initial contribution and API
 */
class PascaniValidator extends AbstractPascaniValidator {

	@Inject extension IQualifiedNameProvider

	public static val DUPLICATE_LOCAL_VARIABLE = "pascani.issue.duplicateLocalVariable"
	public static val DISCOURAGED_USAGE = "pascani.issue.discouragedUsage"
	public static val EXPECTED_CRON_EXPRESSION = "pascani.issue.expectedCronExpression"
	public static val EXPECTED_PERIODICAL = "pascani.issue.expectedPeriodical"
	public static val EXPECTED_WHITESPACE = "pascani.issue.expectedWhitespace"
	public static val INVALID_FILE_NAME = "pascani.issue.invalidFileName"
	public static val INVALID_PACKAGE_NAME = "pascani.issue.invalidPackageName"
	public static val INVALID_PARAMETER_TYPE = "pascani.issue.invalidParameterType"
	public static val INVALID_SELF_IMPORT = "pascani.issue.invalidSelfImport"
	public static val MISSING_TYPE = "pascani.issue.missingType"
	public static val NON_CAPITAL_NAME = "pascani.issue.nonCapitalName"
	public static val NOT_SERIALIZABLE_TYPE = "pascani.issue.notSerializableType"
	public static val UNEXPECTED_CRON_NTH = "pascani.issue.unexpectedCronNth"
	public static val UNEXPECTED_CRON_INCREMENT = "pascani.issue.unexpectedCronIncrement"
	public static val UNEXPECTED_CRON_CONSTANT = "pascani.issue.unexpectedCronConstant"
	public static val UNEXPECTED_CRON_RANGE = "pascani.issue.unexpectedCronRange"
	public static val UNEXPECTED_EVENT_SPECIFIER = "pascani.issue.unexpectedEventSpecifier"
	public static val UNEXPECTED_SPECIAL_CHARACTER = "pascani.issue.unexpectedSpecialCharacter"
	public static val UNSUPPORTED_OPERATION = "pascani.issue.unsupportedOperation"
	
	static val numericalPrimitives = newArrayList('byte', 'short', 'int', 'long', 'float', 'double')

	override boolean isLocallyUsed(EObject target, EObject containerToFindUsage) {
		var isUsed = false;
		if (containerToFindUsage instanceof XBlockExpression) {
			if (containerToFindUsage.eContainer instanceof Namespace) {
				/*
				 * As variables declared within a namespace cannot be used from their containers, 
				 * usage is not checked
				 */
				isUsed = true
			}
		}
		return isUsed || super.isLocallyUsed(target, containerToFindUsage)
	}
	
	def importedEvents(Monitor monitor) {
		if (monitor.extensions != null) {
			return monitor.extensions.declarations
				.filter(ImportEventDeclaration)
				.map[d|d.events]
				.flatten
		}
		return Collections.EMPTY_LIST
	}
	
	def usedNamespaces(Monitor monitor) {
		if (monitor.extensions != null) {
			return monitor.extensions.declarations
				.filter(ImportNamespaceDeclaration)
				.map[d|d.namespace]
		}
		return Collections.EMPTY_LIST
	}

	def fromURItoFQN(URI resourceURI) {
		// e.g., platform:/resource/<project>/<source-folder>/org/example/.../TypeDecl.pascani
		var segments = new ArrayList
		if (resourceURI.segments.size > 1) {
			// Remove the first 3 segments, and return the package and file segments
			segments.addAll(resourceURI.segmentsList.subList(3, resourceURI.segments.size - 1))
			// Remove file extension and add the last segment
			segments.add(resourceURI.lastSegment.substring(0, resourceURI.lastSegment.lastIndexOf(".")))
		} else if(resourceURI.lastSegment.contains(".")) {
			segments.add(resourceURI.lastSegment.substring(0, resourceURI.lastSegment.lastIndexOf(".")))
		} else {
			segments.add(resourceURI.lastSegment)
		}
		return segments.fold("", [r, t|if(r.isEmpty) t else r + "." + t])
	}

	@Check
	def checkMonitorStartsWithCapital(TypeDeclaration typeDecl) {
		if (!Character.isUpperCase(typeDecl.name.charAt(0))) {
			warning("Name should start with a capital", PascaniPackage.Literals.TYPE_DECLARATION__NAME,
				NON_CAPITAL_NAME)
		}
	}

	@Check
	def checkPackageIsLowerCase(Model model) {
		if (!model.name.equals(model.name.toLowerCase)) {
			error("Package name must be in lower case", PascaniPackage.Literals.MODEL__NAME)
		}
	}

	@Check
	def checkTypeDeclarationNameMatchesPhysicalName(TypeDeclaration typeDecl) {
		// e.g., platform:/resource/<project>/<source-folder>/org/example/.../TypeDecl.pascani
		val URI = typeDecl.eResource.URI
		val fileName = URI.lastSegment.substring(0, URI.lastSegment.indexOf(URI.fileExtension) - 1)
		val isPublic = typeDecl.eContainer != null && typeDecl.eContainer instanceof Model

		if (isPublic && !fileName.equals(typeDecl.name)) {
			error("The declared type '" + typeDecl.name + "' does not match the corresponding file name '" + fileName +
				"'", PascaniPackage.Literals.TYPE_DECLARATION__NAME, INVALID_FILE_NAME)
		}
	}

	@Check
	def checkPackageMatchesPhysicalDirectory(Model model) {
		val packageSegments = model.name.split("\\.")
		val fqn = fromURItoFQN(model.typeDeclaration.eResource.URI)
		var expectedPackage = if(fqn.contains(".")) fqn.substring(0, fqn.lastIndexOf(".")) else ""

		if (!Arrays.equals(expectedPackage.split("\\."), packageSegments)) {
			error("The declared package '" + model.name + "' does not match the expected package '" + expectedPackage +
				"'", PascaniPackage.Literals.MODEL__NAME, INVALID_PACKAGE_NAME)
		}
	}

	@Check
	def checkNamespaceNameIsUnique(Namespace namespace) {
		switch (parent : namespace.eContainer) {
			Model: { /* this namespace is public. Nothing to do */
			}
			XBlockExpression: {
				val duplicates = parent.expressions.filter [ e |
					switch (e) {
						VariableDeclaration: e.name.equals(namespace.name)
						Namespace: e.name.equals(namespace.name) && !e.equals(namespace)
						default: false
					}
				]
				if ((parent.eContainer as Namespace).name.equals(namespace.name) || !duplicates.isEmpty) {
					error("Duplicate local variable " + namespace.name, PascaniPackage.Literals.TYPE_DECLARATION__NAME,
						DUPLICATE_LOCAL_VARIABLE)
				}
			}
		}
	}

	/**
	 * Check monitors' internal event declarations
	 */
	@Check
	def checkEventNameIsUnique(Event event) {
		val parent = (EcoreUtil2.getRootContainer(event) as Model).typeDeclaration as Monitor
		var duplicates = parent.body.expressions.filter [ e |
			switch (e) {
				VariableDeclaration: e.name.equals(event.name)
				Event: e.name.equals(event.name) && !e.equals(event)
				default: false
			}
		]
		val importedEvents = parent.importedEvents.filter [ e |
			e.name.equals(event.name)
		]
		if (!duplicates.isEmpty || !importedEvents.isEmpty) {
			error("Duplicate local variable " + event.name, PascaniPackage.Literals.EVENT__NAME,
				DUPLICATE_LOCAL_VARIABLE)
		}
	}
	
	/**
	 * Check events inside an import declaration and its siblings
	 */
	@Check
	def checkEventInImportDeclaration(ImportEventDeclaration importDeclaration) {
		// Event name is unique
		val monitor = (EcoreUtil2.getRootContainer(importDeclaration) as Model).typeDeclaration as Monitor
		val events = monitor.importedEvents
		for (event : importDeclaration.events) {
			val count = events.filter[e|e.name.equals(event.name)].size
			if (count > 1) {
				error("Duplicate local variable " + event.name,
					PascaniPackage.Literals.IMPORT_EVENT_DECLARATION__EVENTS, DUPLICATE_LOCAL_VARIABLE)
			}
		}
		// Event type is allowed to be imported
		for (event : importDeclaration.events) {
			val type = if (event.emitter.cronExpression != null)
					"Periodic"
				else if (event.emitter.eventType.equals(EventType.CHANGE))
					"Change"
				else
					null
			if (type != null) {
				error(type + " events are not allowed to be imported",
					PascaniPackage.Literals.IMPORT_EVENT_DECLARATION__EVENTS, INVALID_PARAMETER_TYPE)
			}
		}
	}
	
	@Check
	def checkIncludeIsExternal(ImportEventDeclaration importDeclaration) {
		val monitor = (EcoreUtil2.getRootContainer(importDeclaration) as Model).typeDeclaration as Monitor
		if (monitor.equals(importDeclaration.monitor)) {
			error("A monitor cannot import events from itself",
				PascaniPackage.Literals.IMPORT_EVENT_DECLARATION__MONITOR, INVALID_SELF_IMPORT)
		}
	}

	@Check
	def checkHandlerNameIsUnique(Handler handler) {
		val parent = handler.eContainer.eContainer as Monitor
		val duplicates = parent.body.expressions.filter [ e |
			switch (e) {
				Handler: e.name.equals(handler.name) && !e.equals(handler)
				default: false
			}
		]

		if (!duplicates.isEmpty) {
			error("Duplicate local handler " + handler.name, PascaniPackage.Literals.HANDLER__NAME,
				DUPLICATE_LOCAL_VARIABLE)
		}
	}

	@Check
	def checkPascaniVariableDeclaration(VariableDeclaration varDecl) {
		val parent = varDecl.eContainer.eContainer // the first parent is a XBlockExpression
		switch (parent) {
			Monitor: {
				val duplicateVars = parent.body.expressions.filter [ v |
					switch (v) {
						VariableDeclaration case v.name.equals(varDecl.name): {
							return !v.equals(varDecl)
						}
						default:
							return false
					}
				]
				val duplicateUsings = parent.usedNamespaces.filter[n|n.name.equals(varDecl.name)]
				if (!duplicateUsings.isEmpty) {
					error("Local variable " + varDecl.name + " duplicates namespace " +
						duplicateUsings.get(0).fullyQualifiedName, PascaniPackage.Literals.VARIABLE_DECLARATION__NAME,
						DUPLICATE_LOCAL_VARIABLE)
				}
				if (!duplicateVars.isEmpty) {
					error("Duplicate local variable " + varDecl.name, PascaniPackage.Literals.VARIABLE_DECLARATION__NAME,
						DUPLICATE_LOCAL_VARIABLE)
				}
			}
			Namespace: {
				/*
				 * As these variables are sent over the network, only Serializable objects 
				 * are allowed to be defined within namespaces
				 */
				val type = varDecl.right.actualType
				if (!type.isPrimitive && type.getSuperType(Serializable) == null) {
					error(
						"Variables must be serializable",
						PascaniPackage.Literals.VARIABLE_DECLARATION__TYPE,
						NOT_SERIALIZABLE_TYPE
					);
				}
				if (varDecl.type == null) {
					error("Missing variable type", 
						PascaniPackage.Literals.VARIABLE_DECLARATION__TYPE, MISSING_TYPE)
				}
			}
		}
	}

	@Check
	def checkHandlerParameters(Handler handler) {
		if (handler.params.size > 2) {
			error("Event handlers cannot have more than two parameters", PascaniPackage.Literals.HANDLER__PARAMS)
		}
		if (handler.params.get(0).actualType.getSuperType(org.pascani.dsl.lib.Event) == null) {
			error('''The«IF handler.params.size > 1» first«ENDIF» parameter must be subclass of Event''', 
				PascaniPackage.Literals.HANDLER__NAME, INVALID_PARAMETER_TYPE)
		}
		if (handler.params.size > 1) {
			val actualType = handler.params.get(1).actualType.getSuperType(Map)
			val showError = actualType == null
				|| actualType.typeArguments.size != 2
				|| !actualType.typeArguments.get(0).identifier.equals(String.canonicalName)
				|| !actualType.typeArguments.get(1).identifier.equals(Object.canonicalName)
			if (showError)
				error('''The second parameter must be of type Map<String, Object>''', 
					PascaniPackage.Literals.HANDLER__NAME, INVALID_PARAMETER_TYPE)
		}
	}
	
	@Check
	def checkEventIsWellForm(Event event) {
		if (event.emitter.cronExpression != null && !event.isPeriodical) {
			error("Chronological events must be raised periodically", PascaniPackage.Literals.EVENT__PERIODICAL,
				EXPECTED_PERIODICAL)
		}
		if (event.isPeriodical 
			&& !event.emitter.cronExpression.actualType.isAssignableFrom(org.quartz.CronExpression)
			&& !event.emitter.cronExpression.actualType.isAssignableFrom(CronConstant)) {
			error("A chronological expression is expected, instead " +
				event.emitter.cronExpression.actualType.simpleName + " was found",
				PascaniPackage.Literals.EVENT__EMITTER, EXPECTED_CRON_EXPRESSION);
		}
	}

	@Check
	def checkEventSpecifier(EventSpecifier specifier) {
		if (!specifier.equal) {
			val actualType = specifier.value.actualType
			val superTypes = actualType.allSuperTypes.map[t|t.canonicalName]
			val isNumerical = superTypes.contains(Number.simpleName) || numericalPrimitives.map [e |
				actualType.canonicalName.equals(e)
			].exists[v|v]
			if (!isNumerical) {
				error("Only numerical expressions are allowed in this event specifier, instead " + actualType.canonicalName +
					" was found", PascaniPackage.Literals.EVENT_SPECIFIER__VALUE, INVALID_PARAMETER_TYPE)
			}
		}
	}
	
	def boolean errorOnSpecifier(EventSpecifier specifier, LightweightTypeReference emitterType) {
		if (specifier != null) {
			if (specifier instanceof AndEventSpecifier || specifier instanceof OrEventSpecifier) {
				return errorOnSpecifier(specifier.left, emitterType) 
					|| errorOnSpecifier(specifier.right, emitterType)
			} else if(!specifier.equal) {
				val superTypes = emitterType.allSuperTypes.map[t|t.canonicalName]
				val isNumerical = superTypes.contains(Number.simpleName) || numericalPrimitives.map [e |
					emitterType.canonicalName.equals(e)
				].exists[v|v]
				return !isNumerical
			}
		}
		return false
	}
	
	@Check
	def checkEventEmitter(EventEmitter emitter) {
		val emitterType = emitter.emitter.actualType
		if (emitter.eventType.equals(EventType.CHANGE)) {
			// TODO: validate emitter comes from a namespace
			if (emitterType.getSuperType(Serializable) == null) {
				error("The emitter type must be Serializable",
					PascaniPackage.Literals.EVENT_EMITTER__EMITTER, INVALID_PARAMETER_TYPE)
			}
			if (errorOnSpecifier(emitter.specifier, emitterType)) {
				error('''Event specifiers 'above' and 'below' are only allowed for numerical emitters''',
					PascaniPackage.Literals.EVENT_EMITTER__SPECIFIER, INVALID_PARAMETER_TYPE)
			}
			
		} else {
			if (emitter.specifier != null) {
				error("Only change events are allowed to use value specifiers",
					PascaniPackage.Literals.EVENT_EMITTER__SPECIFIER, UNEXPECTED_EVENT_SPECIFIER)
			}
			if (emitterType.getSuperType(String) == null) {
				error("The emitter must be of type String",
					PascaniPackage.Literals.EVENT_EMITTER__EMITTER, INVALID_PARAMETER_TYPE)
			}
		}
	}

	@Check
	def globalValidationsOnCronExp(CronExpression exp) {
		// Validate spaces: all cron parts must be space-separated
		if (isValidCronExp(exp)) {
			val node = NodeModelUtils.getNode(exp)
			val String[] parts = node.text.trim.split(" ")
			var expectedSize = if(exp.year == null) 6 else 7

			if (parts.length != expectedSize)
				warning("Chronological sub-expressions must be separated by one space",
					PascaniPackage.Literals.CRON_EXPRESSION__SECONDS, EXPECTED_WHITESPACE)
		}

		// Quartz limitations
		if (isValidCronExp(exp) &&
			!(isCronElementNoSpecificValue(exp.dayOfMonth) || isCronElementNoSpecificValue(exp.dayOfWeek))) {
			error("Support for specifying both a day-of-month and a day-of-week value is not complete" +
				". You must currently use the '?' character in one of these fields",
				PascaniPackage.Literals.CRON_EXPRESSION__DAY_OF_WEEK, UNSUPPORTED_OPERATION)
		}
	}

	/*
	 * Regular expressions for numerical ranges from: http://utilitymill.com/utility/Regex_For_Range/42
	 */
	@Check
	def checkWellFormedCronExpression(CronExpression exp) {

		// Allowed characters and values are based in:
		// http://www.quartz-scheduler.org/documentation/quartz-2.x/tutorials/crontrigger
		checkSecondsAndMinutesExp(exp.seconds, PascaniPackage.Literals.CRON_EXPRESSION__SECONDS)
		checkSecondsAndMinutesExp(exp.minutes, PascaniPackage.Literals.CRON_EXPRESSION__MINUTES)
		checkHoursExp(exp.hours, PascaniPackage.Literals.CRON_EXPRESSION__HOURS)
		checkDayOfMonthExp(exp.dayOfMonth, PascaniPackage.Literals.CRON_EXPRESSION__DAY_OF_MONTH)
		checkMonthExp(exp.month, PascaniPackage.Literals.CRON_EXPRESSION__MONTH)
		checkDayOfWeekExp(exp.dayOfWeek, PascaniPackage.Literals.CRON_EXPRESSION__DAY_OF_WEEK)

		if (exp.year != null)
			checkYearExp(exp.year, PascaniPackage.Literals.CRON_EXPRESSION__YEAR)
	}

	def boolean isCronElementNoSpecificValue(CronElement e) {
		switch (e) {
			TerminalCronElement:
				return e.expression.matches("\\?")
			CronElementList: {
				if (e.elements.size == 1 && e.elements.get(0) instanceof TerminalCronElement) {
					return (e.elements.get(0) as TerminalCronElement).expression.matches("\\?")
				}
				return false
			}
			default:
				return false
		}
	}

	def isValidCronExp(CronExpression exp) {
		return exp.seconds != null && exp.minutes != null && exp.hours != null && exp.dayOfMonth != null &&
			exp.month != null && exp.dayOfWeek != null
	}

	def checkDayOfWeekExp(CronElement e, EReference reference) {
		val rangeRegex = "\\b0*[1-7]\\b"
		val allowed = #["*", "?", "L"]
		val days = #["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
		val terminal = "(\\*|\\?|L|" + rangeRegex + "|" + days.join("|") + ")"
		val numericalRange = #["1", "7"]
		val literalRange = #["SUN", "SAT"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, rangeRegex, numericalRange, rangeRegex, reference,
					incrementExpMessages(e, numericalRange, numericalRange, allowed))
			NthCronElement:
				checkNthExp(e, reference, nthMessages(e))
			CronElementList: {
				checkSpecialCharactersInList(e, reference)

				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference,
								numericAndLiteralTerminalExpMessages(range, numericalRange, literalRange, allowed))
						RangeCronElement: {
							checkNumericalAndLiteralRanges(range, reference, rangeRegex, days,
								numericalAndLiteralRangeMessages(range, numericalRange, literalRange))
						}
					}
				}
			}
		}
	}

	def checkYearExp(CronElement e, EReference reference) {
		val yearRangeRegex = "\\b0*(19[7-9][0-9]|20[0-9]{2})\\b"
		val incrementRangeRegex = "\\b0*([1-9][0-9]{0,2}|1[0-9]{3}|20[0-9]{2})\\b"
		val allowed = #["*"]
		val terminal = "(\\*|" + yearRangeRegex + ")"
		val yearRangeDesc = #["1970", "2099"]
		val incrementRangeDesc = #["1", "2099"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, yearRangeRegex, yearRangeDesc, incrementRangeRegex, reference,
					incrementExpMessages(e, yearRangeDesc, incrementRangeDesc, allowed))
			NthCronElement:
				error(nthMessages(e).get(0), reference, UNEXPECTED_CRON_NTH)
			CronElementList: {
				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference,
								terminalExpMessages(range, yearRangeDesc, allowed))
						RangeCronElement:
							checkNumericalRangeExp(range, yearRangeRegex, reference,
								numericalRangeExpMessages(range, yearRangeDesc))
					}
				}
			}
		}
	}

	def checkMonthExp(CronElement e, EReference reference) {
		val rangeRegex = "\\b0*([1-9]|1[0-2])\\b"
		val months = #["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
		val allowed = #["*", "?"]
		val terminal = "(\\*|\\?|" + rangeRegex + "|" + months.join("|") + ")"
		val numericalRange = #["1", "12"]
		val literalRange = #["JAN", "DEC"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, rangeRegex, numericalRange, rangeRegex, reference,
					incrementExpMessages(e, numericalRange, numericalRange, allowed))
			NthCronElement:
				error(nthMessages(e).get(0), reference, UNEXPECTED_CRON_NTH)
			CronElementList: {
				checkSpecialCharactersInList(e, reference)

				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference,
								numericAndLiteralTerminalExpMessages(range, numericalRange, literalRange, allowed))
						RangeCronElement: {
							checkNumericalAndLiteralRanges(range, reference, rangeRegex, months,
								numericalAndLiteralRangeMessages(range, numericalRange, literalRange))
						}
					}
				}
			}
		}
	}

	def checkDayOfMonthExp(CronElement e, EReference reference) {
		val rangeRegex = "\\b0*([1-9]|[12][0-9]|3[01])\\b"
		val allowed = #["*", "?", "W", "L"]
		val terminal = "(\\*|\\?|W|L|" + rangeRegex + ")"
		val rangeDesc = #["1", "31"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, rangeRegex, rangeDesc, rangeRegex, reference,
					incrementExpMessages(e, rangeDesc, rangeDesc, allowed))
			NthCronElement:
				error(nthMessages(e).get(0), reference, UNEXPECTED_CRON_NTH)
			CronElementList: {
				checkSpecialCharactersInList(e, reference)

				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference, terminalExpMessages(range, rangeDesc, allowed))
						RangeCronElement:
							checkNumericalRangeExp(range, rangeRegex, reference,
								numericalRangeExpMessages(range, rangeDesc))
					}
				}
			}
		}
	}

	def checkHoursExp(CronElement e, EReference reference) {
		val rangeRegex = "\\b0*([0-9]|1[0-9]|2[0-3])\\b"
		val incrementRegex = "\\b0*([1-9]|1[0-9]|2[0-3])\\b"
		val allowed = #["*", "?"]
		val terminal = "(\\*|\\?|" + rangeRegex + ")"
		val rangeDesc = #["0", "23"]
		val incrementRangeDesc = #["1", "23"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, rangeRegex, rangeDesc, incrementRegex, reference,
					incrementExpMessages(e, rangeDesc, incrementRangeDesc, allowed))
			NthCronElement:
				error(nthMessages(e).get(0), reference, UNEXPECTED_CRON_NTH)
			CronElementList: {
				checkSpecialCharactersInList(e, reference)

				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference, terminalExpMessages(range, rangeDesc, allowed))
						RangeCronElement:
							checkNumericalRangeExp(range, rangeRegex, reference,
								numericalRangeExpMessages(range, rangeDesc))
					}
				}
			}
		}
	}

	def checkSecondsAndMinutesExp(CronElement e, EReference reference) {
		val rangeRegex = "\\b0*([0-9]|[1-5][0-9])\\b"
		val allowed = #["*", "?"]
		val terminal = "(\\*|\\?|" + rangeRegex + ")"
		val rangeDesc = #["0", "59"]

		switch (e) {
			IncrementCronElement:
				checkIncrementExp(e, terminal, rangeRegex, rangeDesc, rangeRegex, reference,
					incrementExpMessages(e, rangeDesc, rangeDesc, allowed))
			NthCronElement:
				error(nthMessages(e).get(0), reference, UNEXPECTED_CRON_NTH)
			CronElementList: {
				checkSpecialCharactersInList(e, reference)

				for (range : e.elements) {
					switch (range) {
						TerminalCronElement:
							checkTerminalExp(range, terminal, reference, terminalExpMessages(range, rangeDesc, allowed))
						RangeCronElement:
							checkNumericalRangeExp(range, rangeRegex, reference,
								numericalRangeExpMessages(range, rangeDesc))
					}
				}
			}
		}
	}

	def checkIncrementExp(IncrementCronElement e, String terminalRegex, String rangeRegex, String[] rangeDesc,
		String incrementRangeRegex, EReference reference, String[] messages) {

		val initial = e.start.expression
		val increment = e.increment.expression
		var ok = true

		if (e.end != null) {
			checkNumericalRangeExp(e.start, e.end, rangeRegex, reference,
				numericalRangeExpMessages(e.start, e.end, rangeDesc))
		} else {
			if (initial.matches("[0-9]+") && !initial.matches(terminalRegex)) {
				error(messages.get(0), reference, UNEXPECTED_CRON_INCREMENT)
				ok = false
			} else if (!initial.matches(terminalRegex)) {
				error(messages.get(1), reference, UNEXPECTED_CRON_INCREMENT)
				ok = false
			}
		}

		if (!increment.matches(incrementRangeRegex)) {
			error(messages.get(2), reference, UNEXPECTED_CRON_INCREMENT)
			ok = false
		}

		if (ok) {
			var initialValue = 0
			val incrementValue = Integer.parseInt(increment)

			if (initial.matches("[0-9]+"))
				initialValue = Integer.parseInt(initial)

			// Possible mistake
			if (!String.valueOf(initialValue + incrementValue).matches(rangeRegex)) {
				warning("These values may cause the event to be raised only one time", reference)
			}
		}
	}

	/*
	 * The legal characters and the names of months and days of the week are not case sensitive
	 */
	def checkTerminalExp(TerminalCronElement element, String regularExpression, EReference reference,
		String[] messages) {

		val integerRegex = "\\b[0-9]+\\b"
		val expression = element.expression
		var message = messages.get(0)

		if (expression.matches(integerRegex)) {
			message = messages.get(1)
		}

		if (!expression.toUpperCase.matches(regularExpression)) {
			error(message, reference, UNEXPECTED_CRON_CONSTANT)
		}
	}

	def checkNumericalRangeExp(RangeCronElement element, String regularExpression, EReference reference,
		String[] messages) {

		checkNumericalRangeExp(element.start, element.end, regularExpression, reference, messages)
	}

	def checkNumericalRangeExp(TerminalCronElement start, TerminalCronElement end, String regularExpression,
		EReference reference, String[] messages) {

		if (!(start.expression.matches(regularExpression) && end.expression.matches(regularExpression))) {
			error(messages.get(0), reference, UNEXPECTED_CRON_RANGE)
		} else {
			val startInt = Integer.parseInt(start.expression)
			val endInt = Integer.parseInt(end.expression)

			if (startInt > endInt) {
				error(messages.get(1), reference, UNEXPECTED_CRON_RANGE)
			}
		}
	}

	def checkNumericalAndLiteralRanges(RangeCronElement element, EReference reference, String numericalRegex,
		String[] literalValues, String[] messages) {

		val literalRegex = literalValues.join("|")
		val start = element.start.expression.toUpperCase
		val end = element.end.expression.toUpperCase

		if (!(start.matches(numericalRegex) && end.matches(numericalRegex)) &&
			!(start.matches(literalRegex) && end.matches(literalRegex))) {
			error(messages.get(0), reference, UNEXPECTED_CRON_RANGE)
		} else {
			val numerical = start.matches(numericalRegex)
			val _start = if(numerical) Integer.parseInt(start) else literalValues.indexOf(start)
			val _end = if(numerical) Integer.parseInt(end) else literalValues.indexOf(end)

			if (_start > _end) {
				error(messages.get(1), reference, UNEXPECTED_CRON_RANGE)
			}
		}
	}

	def checkSpecialCharactersInList(CronElementList e, EReference reference) {
		val messages = listMessages(e)
		val size = e.elements.size
		val text = NodeModelUtils.getNode(e).text

		switch (size) {
			case size > 1 && text.contains("?"): error(messages.get(0), reference, UNEXPECTED_SPECIAL_CHARACTER)
			case size > 1 && text.contains("*"): error(messages.get(1), reference, UNEXPECTED_SPECIAL_CHARACTER)
		}
	}

	def checkNthExp(NthCronElement e, EReference reference, String[] messages) {
		val leftRegex = "[1-7]" // day of week
		val rightRegex = "[1-5]" // nth day in the month
		if (!e.element.expression.matches(leftRegex) || !e.nth.expression.matches(rightRegex)) {
			error(messages.get(1), reference, UNEXPECTED_CRON_NTH)
		} else {
			val nth = Integer.parseInt(e.nth.expression)

			if (nth == 5)
				info(messages.get(2), reference)
		}
	}

	def String[] incrementExpMessages(IncrementCronElement e, String[] rangeDesc, String[] incrementRangeDesc,
		String ... allowedTerminals) {
		#[
			'''Invalid value '«NodeModelUtils.getNode(e).text»', numerical values must be between «rangeDesc.join(" and ")»''',
			'''Invalid value '«NodeModelUtils.getNode(e).text»'. Allowed values are «allowedTerminals.join(", ")» or numerical values between «rangeDesc.join(" and ")»''',
			'''Invalid value '«e.increment.expression»'. Valid increments must be numerical values between «incrementRangeDesc.join(" and ")»'''
		]
	}

	def String[] terminalExpMessages(TerminalCronElement e, String[] rangeDesc,
		String ... allowedTerminals) {
		#[
			'''Unexpected expression '«e.expression»'. Valid inputs are «allowedTerminals.join(", ")» or numerical values between «rangeDesc.join(" and ")»''',
			'''Invalid value, numerical values must be between «rangeDesc.join(" and ")»'''
		]
	}

	def String[] numericAndLiteralTerminalExpMessages(TerminalCronElement e, String[] numericRange,
		String[] literalRange,
		String ... allowedTerminals) {
			#[
				'''Unexpected expression '«e.expression»'. Valid inputs are «allowedTerminals.join(", ")» or values within «numericRange.join(" and ")», or «literalRange.join(" and ")»''',
				'''Invalid value, numerical values must be between «numericRange.join(" and ")»'''
			]
		}

		def String[] numericalRangeExpMessages(RangeCronElement e, String[] rangeDesc) {
			return numericalRangeExpMessages(e.start, e.end, rangeDesc)
		}

		def String[] numericalRangeExpMessages(TerminalCronElement start, TerminalCronElement end,
			String[] rangeDesc) {
			#[
				'''Unexpected range expression '«start.expression»-«end.expression»'. Valid ranges must contain numerical values between «rangeDesc.join(" and ")»''',
				'''Invalid range. The start field may not be greater than the end field'''
			]
		}

		def String[] numericalAndLiteralRangeMessages(RangeCronElement e, String[] numericalRange,
			String[] literalRange) {
			#[
				'''Unexpected range expression '«e.start.expression»-«e.end.expression»'. Valid ranges must contain values between «numericalRange.join(" and ")», or «literalRange.join(" and ")»''',
				'''Invalid range. The start field may not be after the end field'''
			]
		}

		def String[] nthMessages(
			NthCronElement e) {
			#[
				'''Nth expressions are only allowed in the day-of-week field''',
				'''Unexpected expression '«e.element.expression»#«e.nth.expression»'. Valid inputs are of the form 1-7#1-5''',
				'''If there is not 5th of the given day-of-week in the month, then no firing will occur that month'''
			]
		}

		def String[] listMessages(CronElementList e) {
			#[
				'''The special character '?' may not be included in a list''',
				'''The special character '*' should not be included in a list'''
			]
		}

		@Check
		def checkUseOfJavaLangNames(TypeDeclaration typeDecl) {
			val ClassLoader classLoader = this.getClass().getClassLoader();
			try {
				val clazz = classLoader.loadClass("java.lang." + typeDecl.name);
				warning("The use of type name " + typeDecl.name +
						" is discouraged because it can cause unexpected behavior with members from class " +
						clazz.canonicalName, PascaniPackage.Literals.TYPE_DECLARATION__NAME, DISCOURAGED_USAGE)

				} catch (ClassNotFoundException e) {
				}
			}
		}
		