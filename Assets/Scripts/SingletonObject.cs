using UnityEngine;

public class SingletonObject : MonoBehaviour
{
    private static SingletonObject _Instance;

    private void Awake()
    {
        if (_Instance == null)
        {
            _Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
}
