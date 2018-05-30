properties([buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))])

node('Xcode9') {
try {

stage ('Build') {
env.App_Name = "PDP8/E Simulator"
env.JENKINS_CFBundleVersion = VersionNumber(versionNumberString: '${BUILD_DATE_FORMATTED, "yyMMddHHmm"}')
env.FASTLANE_DISABLE_COLORS = "1"
env.LC_CTYPE = "en_US.UTF-8"
env.LC_ALL = "en_US.UTF-8"
env.LANG = "en_US.UTF-8"
checkout scm
sh '''#!/bin/sh -li
bundle exec fastlane mac home
'''
}

} catch (e) {
// If there was an exception thrown, the build failed
currentBuild.result = "FAILED"
throw e
} finally {
// Success or failure, always send notifications
notifyBuild(currentBuild.result)
}

}

def notifyBuild(String buildStatus = 'STARTED') {
// build status of null means successful
buildStatus =  buildStatus ?: 'SUCCESSFUL'

// Default values
def colorName = 'RED'
def colorCode = '#FF0000'
def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
def summary = "${subject} (${env.BUILD_URL})"

// Override default values based on build status
if (buildStatus == 'STARTED') {
color = 'YELLOW'
colorCode = '#FFFF00'
} else if (buildStatus == 'SUCCESSFUL') {
color = 'GREEN'
colorCode = '#00FF00'
} else {
color = 'RED'
colorCode = '#FF0000'
}

// Send notifications
slackSend (color: colorCode, message: summary)
try {
sh "jenkins-growl $buildStatus"
} catch (e) {
// Fail silently
}
}

