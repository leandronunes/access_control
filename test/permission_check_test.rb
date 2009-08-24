require File.join(File.dirname(__FILE__), 'test_helper')

class AccessControlTestController; def rescue_action(e) raise e end; end
class PermissionCheckTest < Test::Unit::TestCase

  def setup
    @controller = AccessControlTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_access_denied
    get :index
    assert_response 403
    assert_template 'access_denied.rhtml'
  end

  def test_global_permission_granted
    user = AccessControlTestAccessor.create!(:name => 'user')
    role = Role.create!(:name => 'some_role', :permissions => ['see_index'])
    assert user.add_role(role, 'global')
    assert user.has_permission?('see_index', 'global')

    get :index, :user => user.id
    assert_response :success
    assert_template nil

    # Same test with a hash parameter passed to controller
    @controller = AnotherAccessControlTestController.new
    get :index, :user => user.id
    assert_response :success
    assert_template nil
  end

  def test_last_parameter_are_the_actions_if_hash_is_passed
    AccessControlTestAccessor.delete_all
    AccessControlTestResource.delete_all
    Role.delete_all
    user = AccessControlTestAccessor.create!(:name => 'other_user')
    role = Role.create!(:name => 'test_accessor', :permissions => ['test_accessor'])
    resource = AccessControlTestResource.create!(:name => 'some_resource')
    assert user.add_role(role, resource)
    assert user.has_permission?('test_accessor', resource)

    get :test_accessor, :user => user.id, :resource => resource.id
    assert_response :success
    assert_template nil

  end

  def test_specific_permission_granted
    AccessControlTestAccessor.delete_all
    AccessControlTestResource.delete_all
    Role.delete_all
    user = AccessControlTestAccessor.create!(:name => 'other_user')
    role = Role.create!(:name => 'other_role', :permissions => ['do_some_stuff'])
    resource = AccessControlTestResource.create!(:name => 'some_resource')
    assert user.add_role(role, resource)
    assert user.has_permission?('do_some_stuff', resource)

    get :other_stuff, :user => user.id, :resource => resource.id
    assert_response :success
    assert_template nil

    # Same test with a hash parameter passed to controller
    @controller = AnotherAccessControlTestController.new
    get :other_stuff, :user => user.id, :resource => resource.id
    assert_response :success
    assert_template nil
  end

  def test_conditions_for_access_control_are_granted
    AccessControlTestAccessor.delete_all
    AccessControlTestResource.delete_all
    Role.delete_all
    user = AccessControlTestAccessor.create!(:name => 'other_user')
    resource = AccessControlTestResource.create!(:name => 'some_resource')
   
    AccessControlTestController.any_instance.expects(:check_permission?).returns(false)

    get :other_stuff, :user => user.id, :resource => resource.id
    assert_response :success
    assert_template nil
  end

end
