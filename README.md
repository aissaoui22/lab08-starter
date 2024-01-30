[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/BJ1FAb8s)
Lab 8: Rails Authentication using BandBlitz application
-
Objectives
-

- Teach students how to do basic authentication with Rails
- Experiment with Controller TDD
- Reinforce previous lessons in rapidly building apps

Due Date:
-

**March 7, 2024** by the end of your lab session!

Important Note
===============

In this lab, you have a total of **2 checkpoints** to validate with one of the teaching team members during the lab session.

Checkpoints will be graded as follows:

- Checkpoint 1 Authentication Part: 60 points
- Checkpoint 2 Controller TDD part: 40 points


This lab will serve as an introduction to working with sessions and authentication using the Ruby on Rails framework.

### Part 1: Sessions and Authentication

1. We are going to be working with a project known as BandBlitz.  This app allows for bands to post information about themselves as well as a small musical sample.  It also allows guests to post comments about the band for others to see.  Unregistered users can read everything, but can only post comments.  If a band manager is made a user, he/she can update the band's information and remove the band from BandBlitz if they so desire.  Regular band members can update the information, but cannot delete the band's entry.  Administrators can do it all – all CRUD operations on both bands and genres and is the only user that can delete a comment left for a band (in case there is libel, obscene remarks, etc.).  Begin by getting the base project code off of github. 

Once you get the starter code, run `bundle install` to get the gems we will need for this lab.

2. We first begin by adding authentication.  To do this, create a user model with the following attributes: 

    **User**
    first_name (string)
    last_name (string)
    email (string)
    role (string)
    password_digest (string)
    band_id (integer)
    active (boolean) 
 
    (Use `rails generate model` for now; some user views you will need are already included in starter files.) In the migration set the default value of `role` to "member" and the default value of `active` to true.  Run `rails db:migrate` to capture these changes.

3. In the `User` model, create a relationship to `Band` (and likewise from `Band` to `User`). Note a band `has_many` users and a user `belongs_to` a band.

4. We also want to use Rails' built-in password management, so add the line `has_secure_password` to your User model as well.  This will create the password-digest, but you will need the bcrypt gem for this to work (make sure it's in your `Gemfile`).  
Add appropriate validation to this model as well as a name method called `proper_name` which concatenates the user's first and last names. For validations consider that `first_name`, `last_name`, and `email` must be present, `email` is unique and `email` follows an email regex pattern (such as the one in PATS).  

    As an option, you can also add the following class method to handle logging in via email and use this method later in the sessions_controller (this was demoed in class last week and we'll point out where it would go later in the lab):

  ```ruby
    def self.authenticate(email,password)
      find_by_email(email).try(:authenticate, password)
    end
  ```

  Quick question: you are saving your work to git, right?

5. We are going to go to the ApplicationController (controllers/application_controller.rb) and add some methods we want all controllers to have for authentication purposes.  The first will be the `current_user`, which we will draw from the session hash (if it is saved... will do that in a moment).  We also want to make this a helper method so that our views can access it later.  We will create a `logged_in?` method which simply tells us if you are logged in (true if you have a user_id in session hash, i.e., a current_user).  Finally, we will have a method called `check_login` that we can use as an additional before_action in other controllers.  The code would be as follows:

  ```ruby
    private
    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
    helper_method :current_user
  
    def logged_in?
      current_user
    end
    helper_method :logged_in?
  
    def check_login
      redirect_to login_url, alert: "You need to log in to view this page." if current_user.nil?
    end
  ```

6. Now that we have a `check_login` method in ApplicationController, every other controller will also have it because they inherit from ApplicationController.  

    To use this method set up an additional `before_action` to require `check_login` be run before any action in the GenresController, and before all actions except index and show in the BandsController. See the [Rails Guide](http://guides.rubyonrails.org/action_controller_overview.html#filters) for more information on filters if you are unsure of how to do this.

7. We need to set up a UsersController and it will be much like our standard controllers with the following exceptions:

  a) We only need new, edit, create, and update actions in this simple app (you can add more if you like, but will also need to add views)
  b) `edit` and `update` should get initial object from `current_user` method, not an id parameter passed in
  c) When a new user is saved during the create method, the user_id should be added to the session hash: `session[:user_id] = @user.id` and the user should be redirected to `home_path`
  d) In the private `user_params` method, allow all attributes except `:password_digest` and replace that with `:password` and `:password_confirmation`
  e) In the `new` method, be sure to set @user = User.new

  The UsersController is not provided. To generate it, **DO NOT** run the rails generator.  Just create an empty file called `users_controller.rb` and build this controller manually. (Not hard; look at past projects/labs if you are unsure how to do this.)

8. We also need a SessionsController to handle logging in for users who already exist in the system. Create this file from scratch as well.  

    We need a new method which is essentially blank, but let's the user get a login form (provided).  We need a create method which tries to authenticate and if successful sets the user_id in session.  Finally, we need a destroy method for logout which destroys the user_id in session (clearing the session).  In the interest of time, the code for all this can be seen below:

  ```ruby
    class SessionsController < ApplicationController
      def new
      end
  
      def create
        user = User.find_by_email(params[:email])
        if user && user.authenticate(params[:password])
          session[:user_id] = user.id
          redirect_to home_path, notice: "Logged in!"
        else
          flash.now.alert = "Email or password is invalid"
          render "new"
        end
      end
  
      def destroy
        session[:user_id] = nil
        redirect_to home_path, notice: "Logged out!"
      end
    end
  ```

  Note: if you created the class method earlier in the User model, you could use that instead to rewrite/replace the first two lines of the create action.  This is optional, but it would be a good learning exercise at some point to do this and make sure you have a good grasp of what is happening when creating a user's session.

9. Now we have controllers and the views were already given to us, but without routes these controllers will never be called.  So go to `config/routes.rb` and add the following routes:

  ```ruby
    resources :users
    resources :sessions
    get 'user/edit' => 'users#edit', :as => :edit_current_user
    get 'signup' => 'users#new', :as => :signup
    get 'login' => 'sessions#new', :as => :login
    get 'logout' => 'sessions#destroy', :as => :logout

    # Default route
    root :to => 'bands#index', :as => :home
  ```

  Now run `rails routes` from the terminal to update the routes.

10. Now we will add a default user (admin) to the system using migrations (since all new sign-ups are going to be members only unless an admin is signing them up and chooses a different level).  An example of the up and down methods for this migration are below; create a new migration with `rails generate migration [NAME]` (remove the change method in this new migration) and add these methods:

  ```ruby
    def up
      adminBand = Band.new
      adminBand.name = "Admin Band"
      adminBand.description = "An initial band to create users"
      adminBand.save
      admin = User.new
      admin.first_name = "Admin"
      admin.last_name = "Admin"
      admin.email = "admin@example.com"
      admin.band_id = adminBand.id
      admin.password = "secret"
      admin.password_confirmation = "secret"
      admin.role = "admin"
      admin.save
    end
    def down
      admin = User.find_by_email "admin@example.com"
      User.delete admin
      band = Band.find_by_name "Admin Band"
      Band.delete band
    end
  ```
  Now run `rails db:migrate` to get this user into the system.

11. Now we will test this out by attempting to log in as the default user. Start the server and try to log-in with the email and password we have in the migration (navigate to /login). This seems to work (you get a flash message saying 'Logged in!') but it would be nice to add some personal information to the page.  In the application layout file, add to the div id="login" the following and reload the page to verify:

  ```erb
    <% if logged_in? %>
      <%= link_to 'Logout', logout_path %>
      <br>[<%= current_user.proper_name %>:<%= current_user.role %>]
    <% else %>
      <%= link_to 'Login', login_path %>
    <% end %>
  ```

- - -
**Checkpoint**
Show a CA that you have the authentication functionality set up and working as instructed and that the code is properly saved to git. Note: When you do git add, please note that you should use git add BandBlitzStarter/*
- - -
Part 2. University
-

This part of the lab is dedicated to a simple TDD (Test-Driven Development) task, where you are provided with a starter code and you will complete one controller. 

We have given you with the DepartmentsController tests under `test/controllers/departments_controller_test.rb`, as well as the Department model, and all the testing setup and contexts. You will need to build a controller for departments that handles all the tests provided for you.  


 Do not forget to specify the routes! 

1. To start this exercise, start by a `cd` to the  University-starter-code folder, and run `bundle install`, then `rails db:migrate`.

2. First run `rails db:contexts` and reset the database and create a series of departments to work with.

3. Run the tests right now with the command `rails test:controllers` and see that all the tests fail, and bunch of errors are raised (This is expected because we have no controllers or routes defined yet.). 

4. Read over the tests and see what they are doing and what is expected. (See comments on first test for more help.)

5. Add a new file called departments_controller.rb (pluralization important) within the app/controller/ directory. Inside the file, add the following: 

  ```
  class DepartmentsController < ApplicationController

  end
  ```

6. Complete the DepartmentsController that to pass all the tests provided in DepartmentsController test file. 

7. Create a series of CRUD operation routes in config/routes.rb (This can be a one-liner). Set the root to the departments#index action. This is already done for you.Verify that this is working by running `rails routes` on the command line of the terminal and see the routes that are generated.

8. With your routes in hand and all the actions created in your controller, confidently run your tests again with `rails test:controllers` and see them all pass. Oops! they are still not passing!

9. Create a `departments` folder under app/views and add the appropriate templates to make all the tests pass. No need to fill their contents.

10. Make sure you achieve a 100% coverage, by opening the index.html file under the coverage folder.

# <span class="mega-icon mega-icon-issue-opened"></span> Stop

**Checkpoint 2**: Show a CA that you have completed this part of the lab by showing the DepartmentsController actions  you defined and a 100% coverage of all the code.


