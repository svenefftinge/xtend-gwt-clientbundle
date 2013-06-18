package org.eclipse.xtend.gwt.clientbundle.client

import com.google.gwt.core.client.GWT
import com.google.gwt.dev.util.log.PrintWriterTreeLogger
import com.google.gwt.resources.client.ClientBundle.Source
import com.google.gwt.resources.client.CssResource.ClassName
import com.google.gwt.resources.client.ImageResource
import com.google.gwt.resources.css.DefsCollector
import com.google.gwt.resources.css.ExtractClassNamesVisitor
import com.google.gwt.resources.css.GenerateCssAst
import java.io.File
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.net.URL
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsParticipant
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration

@Target(ElementType.TYPE)
annotation CssResource {
	String value
	String[] csses
}

@Target(ElementType.TYPE)
annotation ImageResources {
	String value
}

@Target(ElementType.TYPE)
@Active(CliendBundleProcessor)
annotation ClientBundle {
	String value
}

class CliendBundleProcessor implements RegisterGlobalsParticipant<InterfaceDeclaration>, TransformationParticipant<MutableInterfaceDeclaration> {

	private static final String INSTANCE = 'INSTANCE'

	private static final String[] FORMATS = #["jpeg", "png", "bmp", "wbmp", "gif"]

	override doRegisterGlobals(List<? extends InterfaceDeclaration> annotatedSourceElements,
		RegisterGlobalsContext context) {
		for (InterfaceDeclaration it : annotatedSourceElements) {
			doRegisterGlobals(context)
		}
	}

	def doRegisterGlobals(InterfaceDeclaration it, extension RegisterGlobalsContext context) {
		registerClass(getUtilTypeName)
		for (cssResource : getCssResources) {
			registerInterface(getCssResourceTypeName(cssResource))
		}
	}

	def getCssResourceTypeName(InterfaceDeclaration it, AnnotationReference cssResource) {
		'''«getPackageName».«cssResource.getValue.toFirstUpper»CssResource'''.toString
	}

	def getPackageName(InterfaceDeclaration it) {
		qualifiedName.substring(0, qualifiedName.length - simpleName.length - 1)
	}

	def getUtilTypeName(InterfaceDeclaration it) {
		'''«qualifiedName».Util'''.toString
	}

	override doTransform(List<? extends MutableInterfaceDeclaration> annotatedTargetElements,
		extension TransformationContext context) {
		for (MutableInterfaceDeclaration it : annotatedTargetElements) {
			doTransform(context)
		}
	}

	def doTransform(MutableInterfaceDeclaration it, extension TransformationContext context) {
		extendedInterfaces = extendedInterfaces + #[com.google.gwt.resources.client.ClientBundle.newTypeReference]
		val utilType = findClass(getUtilTypeName)
		val clientBundleType = newTypeReference
		utilType.addField(INSTANCE,
			[
				static = true
			]).type = clientBundleType

		val clientBundle = findAnnotation(ClientBundle.newTypeReference.type)
		val projectDirectory = new File(clientBundle.getValue)
		if (!projectDirectory.isValid) {
			clientBundle.addError("Project directory does not exist or it's not a directory.")
			return
		}

		for (cssResource : getCssResources) {
			val cssResourceType = findInterface(getCssResourceTypeName(cssResource))
			cssResourceType.doTransform(clientBundle, cssResource, context)

			addMethod(cssResource.getValue,
				[
					addAnnotation(Source.newTypeReference.type) => [
						set("value", cssResource.getCsses)
					]
				]).returnType = cssResourceType.newTypeReference
		}

		val imageResource = findAnnotation(ImageResources.newTypeReference.type)
		if (imageResource != null) {
			val imageDirectory = new File('''«clientBundle.getValue»«imageResource.getValue»''')
			if (!imageDirectory.isValid) {
				imageResource.addError("Image directory does not exist or it's not a directory.")
				return
			}
			imageDirectory.listFiles [ dir, name |
				FORMATS.map[format|name.toLowerCase.endsWith(format)].reduce[sf1, sf2|(sf1 || sf2)]
			].forEach [ file |
				addMethod(file.name.getMethodName) [
					returnType = ImageResource.newTypeReference
					addAnnotation(Source.newTypeReference.type) => [
						set("value",
							'''«imageResource.getValue»«IF !imageResource.getValue.endsWith('/')»/«ENDIF»«file.name»''')
					]
				]
			]
		}

		val getMethodBody = '''
		if («INSTANCE» == null) {
			«INSTANCE» = «GWT.name».create(«clientBundleType.simpleName».class);
			«FOR cssResource : getCssResources»
				«INSTANCE».«cssResource.getValue»().ensureInjected();
			«ENDFOR»
		}
		return «INSTANCE»;'''
		utilType.addMethod('get',
			[
				static = true
				body = [getMethodBody]
			]).returnType = clientBundleType
	}

	def isValid(File file) {
		file.exists && file.directory
	}

	def doTransform(MutableInterfaceDeclaration it, AnnotationReference clientBundle, AnnotationReference cssResouce,
		extension TransformationContext context) {
		extendedInterfaces = extendedInterfaces + #[com.google.gwt.resources.client.CssResource.newTypeReference]
		val cssStylesheet = GenerateCssAst.exec(new PrintWriterTreeLogger,
			cssResouce.getCsses.map [
				'''«clientBundle.getValue»«it»'''
			].filter [
				if (!new File(it).exists) {
					cssResouce.addError("File does not exist: " + it)
					return false
				}
				true
			].map [
				new URL('''file:«it»''')
			]);
		val defsCollector = new DefsCollector();
		defsCollector.accept(cssStylesheet);
		defsCollector.defs.forEach [ ^def |
			addMethod(def) [
				returnType = String.newTypeReference
			]
		]

		ExtractClassNamesVisitor.exec(cssStylesheet).forEach [ className |
			val methodName = className.getMethodName
			addMethod(it, methodName, className, context)
		]
	}

	def MutableMethodDeclaration addMethod(MutableInterfaceDeclaration it, String methodName, String className,
		extension TransformationContext context) {
		if (findMethod(methodName) == null) {
			return addMethod(methodName) [
				returnType = String.newTypeReference
				addAnnotation(ClassName.newTypeReference.type) => [
					set("value", className)
				]
			]
		}
		addMethod('''«methodName»Class''', className, context)
	}

	def getMethodName(String className) {
		val sb = new StringBuilder()
		var c = className.charAt(0)
		if (Character.isJavaIdentifierStart(c)) {
			sb.append(Character.toLowerCase(c))
		}

		var i = 0
		val j = className.length
		var nextUpCase = false
		while (i + 1 < j) {
			i = i + 1
			c = className.charAt(i)
			if (!Character.isJavaIdentifierPart(c)) {
				nextUpCase = true
			} else {
				if (nextUpCase) {
					nextUpCase = false
					c = Character.toUpperCase(c)
				}
				sb.append(c)
			}
		}
		return sb.toString();
	}

	def List<String> getCsses(AnnotationReference it) {
		val value = getValue("csses")
		switch value {
			String: #[value]
			default: value as List<String>
		}
	}

	def getValue(AnnotationReference it) {
		getValue("value") as String
	}

	def getCssResources(InterfaceDeclaration it) {
		annotations.filter[annotationTypeDeclaration.qualifiedName == CssResource.name]
	}

}
