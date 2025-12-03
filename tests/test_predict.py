from crop_ai.predict import ModelAdapter


def test_model_adapter_load_and_predict():
    adapter = ModelAdapter(framework="stub", model_path="/tmp/model")
    adapter.load()
    assert adapter.model is not None
    outputs = adapter.predict(["abc", "", [1, 2, 3], 123])
    # lengths: 3,0,3, fallback 1
    assert outputs == [3, 0, 3, 1]
