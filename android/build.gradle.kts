allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = "com.example.${project.name.replace("-", "_")}"
            }
        }
    }
}

// Fix for modern AGP 8.0+ package attribute conflict
subprojects {
    afterEvaluate {
        val pluginNamespace = "com.example.${project.name.replace("-", "_")}"
        project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java).apply {
            if (namespace == null) {
                namespace = pluginNamespace
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
