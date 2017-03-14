ExUnit.configure(capture_log: true)
ExUnit.start()

# sets up the default instance to use a fake cas we start
FakeCas.Support.initialize
