extends "res://test/gut_test.gd"

class TestBasics:
	extends "res://test/gut_test.gd"
	const TEMP_FILES = 'user://test_doubler_temp_file'
	var gr = {
		gut = null,
		test = null
	}

	var _last_double_count = 0

	func before_each():
		gr.gut = Gut.new()
		gr.test = Test.new()
		gr.test.gut = gr.gut
		# forces everything to have a unique name across tests
		gr.gut.get_doubler()._double_count = _last_double_count

	func after_each():
		_last_double_count = gr.gut.get_doubler()._double_count
		gr.gut.get_doubler().clear_output_directory()
		gr.gut.get_spy().clear()

	func test_double_returns_a_class():
		var D = gr.test.double(DOUBLE_ME_PATH)
		assert_ne(D.new(), null)

	func test_double_sets_stubber_for_doubled_class():
		var d = gr.test.double(DOUBLE_ME_PATH).new()
		assert_eq(d.__gut_metadata_.stubber, gr.gut.get_stubber())

	func test_basic_double_and_stub():
		var d = gr.test.double(DOUBLE_ME_PATH).new()
		gr.test.stub(DOUBLE_ME_PATH, 'get_value').to_return(10)
		assert_eq(d.get_value(), 10)

	func test_get_set_double_strat():
		assert_accessors(gr.test, 'double_strategy', DOUBLE_STRATEGY.PARTIAL, DOUBLE_STRATEGY.FULL)

	func test_when_strategy_is_full_then_supers_are_spied():
		var doubled = gr.test.double(DOUBLE_ME_PATH, DOUBLE_STRATEGY.FULL).new()
		doubled.is_blocking_signals()
		gr.test.assert_called(doubled, 'is_blocking_signals')
		assert_eq(gr.test.get_pass_count(), 1)

	func test_when_strategy_is_partial_then_supers_are_NOT_spied_in_scripts():
		var doubled = gr.test.double(DOUBLE_ME_PATH, DOUBLE_STRATEGY.PARTIAL).new()
		doubled.is_blocking_signals()
		gr.test.assert_not_called(doubled, 'is_blocking_signals')
		assert_eq(gr.test.get_pass_count(), 1)

	func test_can_override_strategy_when_doubling_scene():
		var doubled = gr.test.double_scene(DOUBLE_ME_SCENE_PATH, DOUBLE_STRATEGY.FULL).instance()
		doubled.is_blocking_signals()
		gr.test.assert_called(doubled, 'is_blocking_signals')
		assert_eq(gr.test.get_pass_count(), 1)
		pause_before_teardown()

	func test_when_strategy_is_partial_then_supers_are_NOT_spied_in_scenes():
		var doubled = gr.test.double_scene(DOUBLE_ME_SCENE_PATH, DOUBLE_STRATEGY.PARTIAL).instance()
		doubled.is_blocking_signals()
		gr.test.assert_not_called(doubled, 'is_blocking_signals')
		assert_eq(gr.test.get_pass_count(), 1)

	func test_can_stub_inner_class_methods():
		var d = gr.gut.get_doubler().double_inner(INNER_CLASSES_PATH, 'InnerA').new()
		gr.test.stub(INNER_CLASSES_PATH, 'InnerA', 'get_a').to_return(10)
		assert_eq(d.get_a(), 10)

	func test_can_stub_multiple_inner_classes():
		var a = gr.gut.get_doubler().double_inner(INNER_CLASSES_PATH, 'InnerA').new()
		var anotherA = gr.gut.get_doubler().double_inner(INNER_CLASSES_PATH, 'AnotherInnerA').new()
		gr.test.stub(a, 'get_a').to_return(10)
		gr.test.stub(anotherA, 'get_a').to_return(20)
		assert_eq(a.get_a(), 10)
		assert_eq(anotherA.get_a(), 20)

	func test_can_stub_multiple_inners_using_class_path_and_inner_names():
		var a = gr.gut.get_doubler().double_inner(INNER_CLASSES_PATH, 'InnerA').new()
		var anotherA = gr.gut.get_doubler().double_inner(INNER_CLASSES_PATH, 'AnotherInnerA').new()
		gr.test.stub(INNER_CLASSES_PATH, 'InnerA', 'get_a').to_return(10)
		assert_eq(a.get_a(), 10)
		assert_eq(anotherA.get_a(), null)

class TestIgnoreMethodsWhenDoubling:
	extends "res://test/gut_test.gd"

	var _test_gut = null
	var _test = null

	func before_each():
		_test_gut = Gut.new()
		_test = Test.new()
		_test.gut = _test_gut

	func test_when_calling_with_path_it_sends_path_to_doubler():
		var m_doubler = double(_utils.Doubler).new()
		_test_gut._doubler = m_doubler
		_test.ignore_method_when_doubling('one', 'two')
		assert_called(m_doubler, 'add_ignored_method', ['one', 'two'])

	func test_when_calling_with_loaded_script_the_path_is_sent_to_doubler():
		var m_doubler = double(_utils.Doubler).new()
		_test_gut._doubler = m_doubler
		_test.ignore_method_when_doubling(load(DOUBLE_ME_PATH), 'two')
		assert_called(m_doubler, 'add_ignored_method', [DOUBLE_ME_PATH, 'two'])

	func test_when_calling_with_scene_the_script_path_is_sent_to_doubler():
		var m_doubler = double(_utils.Doubler).new()
		_test_gut._doubler = m_doubler
		_test.ignore_method_when_doubling(load(DOUBLE_ME_SCENE_PATH), 'two')
		assert_called(m_doubler, 'add_ignored_method', ['res://test/resources/doubler_test_objects/double_me_scene.gd', 'two'])

	func test_when_ignoring_scene_methods_they_are_not_doubled():
		_test.ignore_method_when_doubling(load(DOUBLE_ME_SCENE_PATH), 'return_hello')
		var m_inst = _test.double(DOUBLE_ME_SCENE_PATH).instance()
		m_inst.return_hello()
		# since it is ignored it should not have been caught by the stubber
		_test.assert_not_called(m_inst, 'return_hello')

class TestTestsSmartDoubleMethod:
	extends "res://test/gut_test.gd"
	var _test = null

	func before_all():
		_test = Test.new()
		_test.gut = gut

	func after_each():
		gut.get_stubber().clear()

	func test_when_passed_a_script_it_doubles_script():
		var inst = _test.double(DOUBLE_ME_PATH).new()
		assert_eq(inst.__gut_metadata_.path, DOUBLE_ME_PATH)

	func test_when_passed_a_scene_it_doubles_a_scene():
		var inst = _test.double(DOUBLE_ME_SCENE_PATH).instance()
		assert_eq(inst.__gut_metadata_.path, DOUBLE_ME_SCENE_PATH)

	func test_when_passed_script_and_inner_it_doulbes_it():
		var inst = _test.double(INNER_CLASSES_PATH, 'InnerA').new()
		assert_eq(inst.__gut_metadata_.path, INNER_CLASSES_PATH, 'check path')
		assert_eq(inst.__gut_metadata_.subpath, 'InnerA', 'check subpath')

	func test_full_strategy_used_for_scripts():
		var inst = _test.double(DOUBLE_ME_PATH, DOUBLE_STRATEGY.FULL).new()
		inst.get_instance_id()
		assert_called(inst, 'get_instance_id')

	func test_full_strategy_used_with_scenes():
		var inst = _test.double(DOUBLE_ME_SCENE_PATH, DOUBLE_STRATEGY.FULL).instance()
		inst.get_instance_id()
		assert_called(inst, 'get_instance_id')

	func test_full_strategy_used_with_inners():
		var inst = _test.double(INNER_CLASSES_PATH, 'InnerA', DOUBLE_STRATEGY.FULL).new()
		inst.get_instance_id()
		assert_called(inst, 'get_instance_id')

	func test_when_passing_a_class_of_a_script_it_doubles_it():
		var inst = _test.double(DoubleMe).new()
		assert_eq(inst.__gut_metadata_.path, DOUBLE_ME_PATH)

	func test_when_passing_a_class_of_a_scene_it_doubles_it():
		var inst = _test.double(DoubleMeScene).instance()
		assert_eq(inst.__gut_metadata_.path, DOUBLE_ME_SCENE_PATH)

	func test_when_passing_a_class_of_an_inner_it_doubles_it():
		var inst = _test.double(InnerClasses, 'InnerA').new()
		assert_eq(inst.__gut_metadata_.path, INNER_CLASSES_PATH, 'check path')
		assert_eq(inst.__gut_metadata_.subpath, 'InnerA', 'check subpath')

	func test_can_double_native_classes():
		var inst = _test.double(Node2D).new()
		assert_not_null(inst)

class TestPartialDoubleMethod:
	extends "res://test/gut_test.gd"

	var _gut = null
	var _test = null

	func before_all():
		_gut = Gut.new()
		_test = Test.new()
		_test.gut = _gut

	func after_each():
		_gut.get_stubber().clear()
		_gut.get_doubler().clear_output_directory()

	func test_parital_double_script():
		var inst = _test.partial_double(DOUBLE_ME_PATH).new()
		inst.set_value(10)
		assert_eq(inst.get_value(), 10)

	# TODO this test is tempramental.  It has something to do with the loading
	# of the doubles I think.  Should be fixed.
	func test_partial_double_scene():
		var inst = _test.partial_double(DOUBLE_ME_SCENE_PATH).instance()
		assert_eq(inst.return_hello(), 'hello', 'sometimes fails, should be fixed.')

	func test_partial_double_inner():
		var inst = _test.partial_double(INNER_CLASSES_PATH, 'InnerA').new()
		assert_eq(inst.get_a(), 'a')

	func test_double_script_not_a_partial():
		var inst = _test.double(DOUBLE_ME_PATH).new()
		inst.set_value(10)
		assert_eq(inst.get_value(), null)

	func test_double_scene_not_a_partial():
		var inst = _test.double(DOUBLE_ME_SCENE_PATH).instance()
		assert_eq(inst.return_hello(), null)

	func test_double_inner_not_a_partial():
		var inst = _test.double(INNER_CLASSES_PATH, 'InnerA').new()
		assert_eq(inst.get_a(), null)

	func test_can_spy_on_partial_doubles():
		var pass_count = _test.get_pass_count()
		var inst = _test.partial_double(DOUBLE_ME_PATH).new()
		inst.set_value(10)
		_test.assert_called(inst, 'set_value')
		_test.assert_called(inst, 'set_value', [10])
		assert_eq(_test.get_pass_count(), pass_count + 2)

	func test_can_stub_partial_doubled_native_class():
		var inst = _test.partial_double(Node2D).new()
		_test.stub(inst, 'get_position').to_return(-1)
		assert_eq(inst.get_position(), -1)

	func test_can_spy_on_partial_doubled_native_class():
		var pass_count = _test.get_pass_count()
		var inst = _test.partial_double(Node2D).new()
		inst.set_position(Vector2(100, 100))
		_test.assert_called(inst, 'set_position', [Vector2(100, 100)])
		assert_eq(_test.get_pass_count(), pass_count + 1, 'tests have passed')

	# Test issue 147
	func test_can_double_file():
		var f = File.new()
		print(f.get_class())
		var inst = _test.partial_double(File)
		assert_not_null(inst)
