import jenkins.model.*
import hudson.model.*
import hudson.security.*
import jenkins.install.InstallState

// Users script - Create admin and enable signup, set rights for non-admin users

// Get Jenkins instance
def instance = Jenkins.getInstance()

// Get Security REALM, enable signup
def hudsonRealm = new HudsonPrivateSecurityRealm(true)

// Create user
hudsonRealm.createAccount("admin", "power")
instance.setSecurityRealm(hudsonRealm)

// Set authentication strategy
def strategy = new GlobalMatrixAuthorizationStrategy()

// Allow administrator to administrate the system
strategy.add(Jenkins.ADMINISTER, "admin")

// Grant rights for other users
strategy.add(Jenkins.READ, "authenticated")
strategy.add(Item.READ, "authenticated")
strategy.add(Item.BUILD, "authenticated")
strategy.add(Item.DISCOVER, "authenticated")
strategy.add(Run.UPDATE, "authenticated")

// Set authorization strategy
instance.setAuthorizationStrategy(strategy)

// Mark setup as complete
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

// Save instance
instance.save()
