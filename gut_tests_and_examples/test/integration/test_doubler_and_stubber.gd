extends "res://addons/gut/test.gd"

var Doubler = load('res://addons/gut/doubler.gd')
var Stubber = load('res://addons/gut/stubber.gd')

const DOUBLE_ME_PATH = 'res://gut_tests_and_examples/test/doubler_test_objects/double_me.gd'
const TEMP_FILES = 'user://test_doubler_temp_file'

var gr = {
    doubler = null,
    stubber = null
}

func setup():
    gr.doubler = Doubler.new()
    gr.doubler.set_output_dir(TEMP_FILES)
    gr.stubber = Stubber.new()

func test_doubled_has_null_stubber_by_default():
    var d = gr.doubler.double(DOUBLE_ME_PATH).new()
    assert_eq(d.__gut_metadata_.stubber, null)

func test_doubled_have_ref_to_stubber():
    gr.doubler.set_stubber(gr.stubber)
    var d = gr.doubler.double(DOUBLE_ME_PATH).new()
    assert_eq(d.__gut_metadata_.stubber, gr.stubber)

func test_stubbing_method_returns_expected_value():
    gr.doubler.set_stubber(gr.stubber)
    var D = gr.doubler.double(DOUBLE_ME_PATH)
    gr.stubber.set_return(DOUBLE_ME_PATH, 'get_value', 7)
    assert_eq(D.new().get_value(), 7)

func test_can_stub_doubled_instance_values():
    gr.doubler.set_stubber(gr.stubber)
    var D = gr.doubler.double(DOUBLE_ME_PATH)
    var d1 = D.new()
    var d2 = D.new()
    gr.stubber.set_return(DOUBLE_ME_PATH, 'get_value', 5)
    gr.stubber.set_return(d1, 'get_value', 10)
    assert_eq(d1.get_value(), 10, 'instance gets right value')
    assert_eq(d2.get_value(), 5, 'other instance gets class value')

func test_stubbed_methods_send_parameters_in_callback():
    gr.doubler.set_stubber(gr.stubber)
    gr.stubber.set_return(DOUBLE_ME_PATH, 'has_one_param', 10, [1])
    var d = gr.doubler.double(DOUBLE_ME_PATH).new()
    assert_eq(d.has_one_param(1), 10)
    assert_eq(d.has_one_param('asdf'), null)

func test_stub_with_nothing_works_with_parameters():
    gr.doubler.set_stubber(gr.stubber)
    gr.stubber.set_return(DOUBLE_ME_PATH, 'has_one_param', 5)
    gr.stubber.set_return(DOUBLE_ME_PATH, 'has_one_param', 10, [1])
    var d = gr.doubler.double(DOUBLE_ME_PATH).new()
    assert_eq(d.has_one_param(), 5)
