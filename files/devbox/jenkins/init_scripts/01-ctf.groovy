import jenkins.model.*
import hudson.model.*
import hudson.security.*
import jenkins.install.InstallState

// CtF script -- create CtF build job
// Get Jenkins instance
def instance = Jenkins.getInstance()

// Set job name
def jobName = "suaseclab-ctf"
def job = instance.getItem(jobName)

// Create job
if (job == null) {
    def project = new FreeStyleProject(instance, jobName)

    // Hide the flag here (shell echo) -> edit this file with sed on VM
    def builder = new hudson.tasks.Shell('echo "🚩 FLAG"')
    
    // Add build job
    project.getBuildersList().add(builder)
    instance.reload()
    instance.add(project, jobName)
    project.save()
    project.scheduleBuild2(0)
}