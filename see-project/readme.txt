## Prerequisites

### Hardware

1. Laptop with at least 8 Gb memory (recommended 16 Gb, ideally 32 Gb)


### Software

1. OS Ubuntu 18.04 
2. VirtualBox(v 6.0, or higher)
3. Vagrant (v 2.2.5, or higher)
4. Ansible (v 2.7.5, or higher)



# CI server

## Asset composition (calculator/integration-server)

- a vagrant VM specification (i.e. Vagrant file)
- Ansible playbooks to provision the VM
- GitLab as VCS and CI running into the VM
- Docker service running into the VM


# Stage environment

## Asset composition (calculator/env-stage)
- a vagrant VM specification (i.e. Vagrant file)
- a /scripts folder inside ~/<path_to_folder>/calculator


# Production environment

## Asset composition (calculator/env-prod)
- a vagrant VM specification (i.e. Vagrant file)
- a /scripts folder inside ~/<path_to_folder>/calculator


# Scripts

## Asset composition (calculator/scripts)
- a shell script named "deploy-snapshot.sh"
- a shell script named "setup-tomcat.sh"
- a "config" folder containing:
	- context.xml
	- tomcat.service
	- tomcat-users.xml




## Guidelines


- Clone the repository with:
	git clone https://github.com/DG5-hub/calculator/


1- Get to the integration server working directory
	cd ~/<path_to_folder>/calculator/integration-server


2- Vagrant is used to create a VM which acts as integration server.
	vagrant up
(Might take some minutes)

Connect to the machine with:
	vagrant ssh


3- Edit /etc/gitlab/gitlab.rb 

(Suggestion: sudo nano /etc/gitlab/gitlab.rb)
and replace

	external_url http://hostname
by
	external_url 'http://192.168.33.9/gitlab'
and
	# unicorn['port'] = 8080
by
	unicorn['port'] = 8088
(Don't forget to uncomment)


4- Reconfigure and restart gitlab

	sudo gitlab-ctl reconfigure
(Might take some minutes)
	sudo gitlab-ctl restart unicorn
	sudo gitlab-ctl restart
	

5- Configure docker

5.1- Add a user to the docker group ot be able to access the docker CLI
	sudo usermod -aG docker $YOUR_USERNAME 
(Note: $YOUR_USERNAME = vagrant)


6. Connect to GitLab

6.1 Open http://192.168.33.9/gitlab in your browser.
(If an error 502 appears, just wait and keep refreshing. Might take some time to load up GitLab but shouldn't take more than 1 minute.)

- You will be asked to provide a password (refered as $YOUR_PASSWORD later) for the root credentials.
(Suggestion: $YOUR_ROOT_PASSWORD = 12345678)

- To further login with root the credentials are:
Login: root
Password: $YOUR_ROOT_PASSWORD

6.2 Create a new user on http://192.168.33.9/gitlab

(Sign out from the root if you are logged in)

Click on "Register now" and create a new user
(Suggestion: 
	First name: user1
	Last name: user1
	Username : user1
	Email: user1@git.com
	Password: $YOUR_USER_PASSWORD (suggested: $YOUR_USER_PASSWORD = 12345678)
)

6.3 Accept new created user

- Login to root again (username: root, password: $YOUR_ROOT_PASSWORD)

- Go to the Admin area (flat key icon on the top left)
- Click on  "View latest users"
- Click on "Pending approval"
- Click on the setting of user1 and click on "Approve"


7. Calculator project

7.1 Add calculator project to user1 repository

- Login with user1
- Click on "Get started" as a "Software Developer"
- Click on "Create a project"
- Click on "Create blank project"
- Give a project name (e.g. calculator)
- Click on "Create project"
- Follow the instructions (Follow 'Push an existing folder' if the ~/<path_to_folder>/calculator is not connected to any git
			or follow 'Push an existing Git repository' if otherwise, note: if git remote renaming is impossible just remove .git with "rm -rf .git*" command)
- Refresh the GitLab page (http://192.168.33.9/gitlab/user1/calculator)
			
8. Install GitLab Runner

- Ensure you are in the directory
	~/<path_to_folder>/calculator/integration-server

- Then ssh to the VM by doing
	vagrant ssh

- Install GitLab Runner
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
	sudo apt-get install gitlab-runner
(Might take a few minutes to install gitlab-runner)

9. Register a GitLab Runner
	sudo gitlab-runner register
	http://192.168.33.9/gitlab/
	$GITLAB-CI_TOKEN
	[integration-server] docker
	integration
	docker
	alpine:latest

(Note: $GITLAB-CI_TOKEN can be found on "http://192.168.33.9/gitlab/user1/calculator/-/settings/ci_cd" and then under Runners click "Expand")

	sudo gitlab-runner restart

- Finally, in GitLab change the configuration of the runner to accept jobs without TAGS. (Edit runner and tick the box "Indicates whether this runner can pick jobs without tags")
(On "http://192.168.33.9/gitlab/user1/calculator/-/settings/ci_cd" under Runners "Expand" you can see runner with tag "integration", click on the edit button)


NOTE: leave the integration-server running


# Stage environment

(Open maybe a second terminal/command line)
1. Get to the stage env working directory

	cd ~/<path_to_folder>/calculator/env-stage

	vagrant up


2. Install GitLab Runner

- ssh to the VM by doing
	vagrant ssh

- Install GitLab Runner
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
	sudo apt-get install gitlab-runner


3. Register a GitLab Runner
	sudo gitlab-runner register
	http://192.168.33.9/gitlab/
	$GITLAB-CI_TOKEN
	[env-stage] shell
	env-stage-shell
	shell

	sudo gitlab-runner restart

3.2 Add gitlab-runner user to vagrant's group.

	sudo usermod -a -G vagrant gitlab-runner
	sudo visudo

- Now add the following to the bottom of the file:
	gitlab-runner ALL=(ALL) NOPASSWD: ALL

exit (save content)


4. Restart stage environmnet

	vagrant reload


5. Check Tomcat installation and configuration. Open a browser, and try to access to these URL:

http://192.168.33.11:8080

- In case these URL cannot be reached, then try to fix it by restarting tomcat:
	sudo /opt/tomcat/bin/shutdown.sh
	sudo /opt/tomcat/bin/startup.sh


# CI server (Stage deployment!)

1. On http://192.168.33.9/gitlab/user1/calculator/

- Create file named .gitlab-ci.yml at the root of the repository.
- Add the following lines into the file:


image: maven:3.6.2-jdk-8

variables:
  STAGE_BASE_URL: "http://192.168.33.11:8080"
  PROD_BASE_URL: "http://192.168.33.10:8080"

  # This will suppress any download for dependencies and plugins or upload messages which would clutter the console log.
  # `showDateTime` will show the passed time in milliseconds. You need to specify `--batch-mode` to make this work.
  MAVEN_OPTS: "-Dhttps.protocols=TLSv1.2 -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Djava.awt.headless=true"
  # As of Maven 3.3.0 instead of this you may define these options in `.mvn/maven.config` so the same config is used
  # when running from the command line.
  # `installAtEnd` and `deployAtEnd` are only effective with recent version of the corresponding plugins.
  MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version -DinstallAtEnd=true -DdeployAtEnd=true"

  # Define Tomcat's variables on Staging environment
  APACHE_HOME: "/opt/tomcat"
  APACHE_BIN: "$APACHE_HOME/bin"
  APACHE_WEBAPPS: "$APACHE_HOME/webapps"

  # Define product's variables
  RESOURCE_NAME: "calculator.war"

stages:
  - build
  - unit-test
  - integration-test
  - run
  - upload
  - deploy

cache:
  paths:
    - target/

build_app:
  stage: build
  script:
    - mvn compile

unit_test_app:
  stage: unit-test
  script:
    - mvn test

integration_test_app:
  stage: integration-test
  script:
    - mvn integration-test

run_app:
  stage: run
  script:
    - mvn clean package -Dmaven.test.skip=true

upload_app:
    stage: upload
    tags:
    - integration
    script:
    - echo "Deploy review app"
    artifacts:
        name: "calculator"
        paths:
        - target/*.war

deploy:
    stage: deploy
    tags:
    - env-stage-shell
    script:  
    - echo "Stop Tomcat"
    - sudo service tomcat stop
    
    - echo "Shutdown Tomcat"
    - sudo sh $APACHE_BIN/shutdown.sh
    
    - echo "Deploy generated product into the stage-vm-helloworld environment" 
    - sudo cp target/$RESOURCE_NAME $APACHE_WEBAPPS
    
    - echo "Set user asnd group rights"
    - sudo chown tomcat:tomcat $APACHE_WEBAPPS/$RESOURCE_NAME
    
    - echo "Start up Tomcat"
    - sudo sh $APACHE_BIN/startup.sh



2. The pipeline should have run every stage successfully!
This means that following worked:
	- build
	- unit testing
	- integration testing
	- packaging
	- uploading the application (war file)
	- deploying it in the stage environment


# Stage environment

1. Check URLs work
http://192.168.33.11:8080
http://192.168.33.11:8080/calculator/api/calculator/ping


- In case any of these URLs cannot be reached:
	1. Get to the stage env working directory
		cd ~/<path_to_folder>/calculator/env-stage

	2.Connect via ssh
		vagrant ssh

	3. Go to the shared scripts
		cd /vagrant_scripts

	4. Run the application deployment
		./deploy-snapshot.sh 
	(It might take sometime time for the URLs to work again)

	5. The calculator should be up and running in the stage (test) environment!

- Check following:
http://192.168.33.11:8080/calculator/api/calculator/ping
http://192.168.33.11:8080/calculator/api/calculator/add?x=8&y=26
http://192.168.33.11:8080/calculator/api/calculator/sub?x=12&y=8
http://192.168.33.11:8080/calculator/api/calculator/mul?x=11&y=8
http://192.168.33.11:8080/calculator/api/calculator/div?x=12&y=12

Changing the values of x and y enables you to do any addition (add), substraction (sub), mulitplication (mul) or division (div) !



# Production environment

1. Get to the production env working directory

	cd ~/<path_to_folder>/calculator/env-prod
	vargant up


2. Install GitLab Runner

- ssh to the VM by doing
	vagrant ssh

- Install GitLab Runner
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
	sudo apt-get install gitlab-runner


3. Register a GitLab Runner
	sudo gitlab-runner register
	http://192.168.33.9/gitlab/
	$GITLAB-CI_TOKEN
	[env-prod] shell
	env-prod-shell
	shell

	sudo gitlab-runner restart

3.2 Add gitlab-runner user to vagrant's group.

	sudo usermod -a -G vagrant gitlab-runner
	sudo visudo

- Now add the following to the bottom of the file:
	gitlab-runner ALL=(ALL) NOPASSWD: ALL

exit (save content)


4. Restart prod environmnet

	vagrant reload


5. Check Tomcat installation and configuration. Open a browser, and try to access to these URL:

http://192.168.33.11:8080

- In case these URL cannot be reached, then try to fix it by restarting tomcat:
	sudo /opt/tomcat/bin/shutdown.sh
	sudo /opt/tomcat/bin/startup.sh


# CI server (Production deployment!)

1. On http://192.168.33.9/gitlab/user1/calculator/

- Edit .gitlab-ci.yml
- Change the deploy tag from " - env-stage-shell " to " - env-prod-shell ":

...
deploy:
    stage: deploy
    tags:
    - env-prod-shell
...


2. The pipeline should have run every stage successfully!
This means that following worked:
	- build
	- unit testing
	- integration testing
	- packaging
	- deploying the application (war file)
	- deploying it in the production environment



# Production environment

1. Check if Tomcat is up

http://192.168.33.10:8080

1. Check URLs work
http://192.168.33.10:8080
http://192.168.33.10:8080/calculator/api/calculator/ping

- In case any of these URLs cannot be reached:
	1. Get to the stage env working directory
		cd ~/<path_to_folder>/calculator/env-prod

	2.Connect via ssh
		vagrant ssh

	3. Go to the shared scripts
		cd /vagrant_scripts/

	4. Run the application deployment
		./deploy-snapshot.sh 
	(It might take some time for the URLs to work again)

	5. The calculator should be up and running in the production environment!

- Check following:
http://192.168.33.10:8080/calculator/api/calculator/ping
http://192.168.33.10:8080/calculator/api/calculator/add?x=8&y=26
http://192.168.33.10:8080/calculator/api/calculator/sub?x=12&y=8
http://192.168.33.10:8080/calculator/api/calculator/mul?x=11&y=8
http://192.168.33.10:8080/calculator/api/calculator/div?x=12&y=12

Changing the values of x and y enables you to do any addition (add), substraction (sub), mulitplication (mul) or division (div) !



##

From now on you have the three environments (integration-server, env-stage and env-prod) working.
Each time the staging or production environment is powered off (vagrant halt, for instance) you might have to run the ./deploy-snapshot.sh script to make the application run again.
Don't forget to change the gitlab-ci.yml file if you want to deploy on the staging or on the production environment!

