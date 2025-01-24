package com.taktik.gradle.plugins

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.semver4j.Semver
import org.gradle.process.ExecOperations

import javax.inject.Inject

class GitVersionPlugin implements Plugin<Project> {

    public static final String WRITE_TASK_NAME = "writeGitVersion"
    public static final String PRINT_TASK_NAME = "printGitVersion"
    public static final String FILE_NAME = "git.version"

    private final ClassLoader loader = getClass().classLoader

    @Override
    void apply(Project project) {
        project.ext.gitVersion = getGitVersion(project)
        if (project.hasProperty("jar")) {
            project.jar {
                doFirst {
                    manifest {
                        attributes(
                                "Version": project.ext.gitVersion,
                                "Implementation-Version": project.ext.gitVersion,
                        )
                    }
                }
            }
        }
        // Write version in a file that will be read in dev mode where there is no jar
        (new File("build")).mkdir()
        File buildVersionFile = new File("build/git.version")
        buildVersionFile.write(project.ext.gitVersion + "\n")

        project.task(WRITE_TASK_NAME) {
            doFirst {
                File versionFile = new File(FILE_NAME)
                String version = getGitVersion(project)
                versionFile.write(version + "\n")
                println(version)
            }
        }
        project.task(PRINT_TASK_NAME) {
            doFirst {
                String version = getGitVersion(project)
                println(version)
            }
        }
    }

    interface InjectedExecOps {
        @Inject
        ExecOperations getExecOps()
    }

    def getGitVersion(project) {
        try {
            // Execute shell script
            def scriptContent = loader.getResource("git-version.sh").text
            def stdout = new ByteArrayOutputStream()
            def injected = project.objects.newInstance(InjectedExecOps)
            injected.execOps.exec {
                commandLine 'bash', '-c', scriptContent + "\ngit_version"
                standardOutput = stdout
            }
            def version = stdout.toString().trim()

            // Check Semver validity
            String semver = new Semver(version).toString()
            return semver
        } catch (Exception e) {
            println("WARNING: Could not get git version: ${e.message}")
            return '0.0.0-dev'
        }
    }
}
