module PermissionCheck
  
  module ClassMethods
    # Declares the +permission+ need to be able to access +action+.
    #
    # * +permission+ must be a symbol or string naming the needed permission to
    #   access the specified actions.
    # * +target+ is the object over witch the user would need the specified
    #   permission and must be specified as a symbol or the string 'global'. The controller using
    #   +target+ must respond to a method with that name returning the object
    #   against which the permissions needed will be checked or if 'global' is passed it will be 
    #   cheked if the assignment is global
    # * +accessor+ is a mehtod that returns the accessor who must have the permission. By default
    #   is :user
    # * +action+ must be a hash of options for a before filter like 
    #   :only => :index or :except => [:edit, :update] by default protects all the actions
    def protect(permission, target_method = :environment, accessor = :user, actions = {})
      params = {}
      if permission.is_a?(Hash)
        params[:target] = permission[:target]
        params[:accessor] = permission[:accessor]
        params[:actions] = permission[:actions]
        params[:right] = permission[:right]
      else
        params[:right] = permission
      end

      if accessor.kind_of?(Hash)
        params[:actions] = accessor
        params[:accessor] = :user 
      else
        params[:accessor] ||= accessor
        params[:actions] ||= actions
      end

      params[:target] ||= target_method

      before_filter(params[:actions]) do |c|
        if c.send(:check_permission?)
          target_obj = select_object(c, params[:target]) 
          accessor_obj = select_object(c, params[:accessor])
          unless accessor_obj && accessor_obj.has_permission?(params[:right], target_obj)
            c.send(:render, :file => access_denied_template_path, :status => 403) && false
          end
        end
      end
    end
    
    def access_denied_template_path
      if File.exists?(File.join(RAILS_ROOT, 'app', 'views','access_control' ,'access_denied.rhtml'))
        file_path = File.join(RAILS_ROOT, 'app', 'views','access_control' ,'access_denied.rhtml')
      else
        file_path = File.join(File.dirname(__FILE__),'..', 'views','access_denied.rhtml')
      end
    end
   
    #TODO make a test for this function 
    def select_object(controller, param)
      obj = nil
      begin 
        obj = controller.send(param)
      rescue
        obj = controller.instance_variable_get("@#{param}")
      end
      obj
    end
        
  end

  def self.included(including)
    including.send(:extend, PermissionCheck::ClassMethods)

    #FIXME Make a test for this function.
    # Define if the permission must be checked or not. Replace this method in your controller 
    # to customize it.
    def check_permission?
      true
    end

  end
  
end
