require 'test/unit'
require 'liquid_blocks'

class TestFileSystem
  def read_template_file(path, context)
    if path == 'simple'
      'test'
    elsif path == 'complex'
      %{
        beginning

        {% block thing %}
        rarrgh
        {% endblock %}

        {% block another %}
        bum
        {% endblock %}

      end
      }
    elsif path == 'nested'
      %{
        {% extends 'complex' %}

        {% block thing %}
        from nested
        {% endblock %}

        {% block another %}
        from nested (another)
        {% endblock %}
      }
    else
      %{
        {% extends 'complex' %}

        {% block thing %}
        from nested
        {% endblock %}
      }
    end
  end
end

Liquid::Template.file_system = TestFileSystem.new

class LiquidBlocksTest < Test::Unit::TestCase
  def test_output_the_contents_of_the_extended_template
    template = Liquid::Template.parse %{
      {% extends 'simple' %}

      {% block thing %}
      yeah
      {% endblock %}
    }

    assert_match /test/, template.render
  end

  def test_render_original_content_of_block_if_no_child_block_given
    template = Liquid::Template.parse %{
      {% extends 'complex' %}
    }

    assert_match /rarrgh/, template.render
    assert_match /bum/, template.render
  end

  def test_render_child_content_of_block_if_child_block_given
    template = Liquid::Template.parse %{
      {% extends 'complex' %}

      {% block thing %}
      booyeah
      {% endblock %}
    }

    assert_match /booyeah/, template.render
    assert_match /bum/, template.render
  end

  def test_render_child_content_of_blocks_if_multiple_child_blocks_given
    template = Liquid::Template.parse %{
      {% extends 'complex' %}

      {% block thing %}
      booyeah
      {% endblock %}

      {% block another %}
      blurb
      {% endblock %}
    }

    assert_match /booyeah/, template.render
    assert_match /blurb/, template.render
  end

  def test_remember_context_of_child_template
    template = Liquid::Template.parse %{
      {% extends 'complex' %}

      {% block thing %}
      booyeah
      {% endblock %}

      {% block another %}
      {{ a }}
      {% endblock %}
    }

    res = template.render 'a' => 1234

    assert_match /booyeah/, res
    assert_match /1234/, res
  end

  def test_work_with_nested_templates
    template = Liquid::Template.parse %{
      {% extends 'nested' %}

      {% block thing %}
      booyeah
      {% endblock %}
    }

    res = template.render 'a' => 1234

    assert_match /booyeah/, res
    assert_match /from nested/, res
  end

  def test_work_with_nested_templates_if_middle_template_skips_a_block
    template = Liquid::Template.parse %{
      {% extends 'nested2' %}

      {% block another %}
      win
      {% endblock %}
    }

    res = template.render

    assert_match /win/, res
  end

  def test_render_parent_for_block_super
    template = Liquid::Template.parse %{
      {% extends 'complex' %}

      {% block thing %}
      {{ block.super }}
      {% endblock %}
    }

    res = template.render 'a' => 1234

    assert_match /rarrgh/, res
  end
end
